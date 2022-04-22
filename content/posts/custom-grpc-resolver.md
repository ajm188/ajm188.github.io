---
title: "Implementing a Custom gRPC Resolver"
date: 2022-03-31T06:40:21-04:00
tags:
- golang
- grpc
- vitess
- vtadmin
---

For the last few years, I have been working on a project within [Vitess](https://vitess.io) called [VTAdmin][vtadmin_rfc][^1].
It's an operator-friendly API and UI replacement for the older vtcltd UI control panel.
In order to function, it needs to make gRPC requests to both `vtctld` and `vtgate` components in one (or more!) Vitess deployments.

To connect to `vtgate` and `vtctld` components, VTAdmin relies on a Discovery abstraction, which defines an interface for fetching lists of VTGate and Vtctld addresses:

```go
// (N.B. There are other methods in the interface which I've omitted.)
type Discovery interface {
    DiscoverVTGateAddrs(ctx context.Context, tags []string) ([]string, error)
    DiscoverVtctldAddrs(ctx context.Context, tags []string) ([]string, error)
}
```

VTAdmin wraps these gRPC connections within structs called, respectively, `vtsql.DB` (which proxies to VTGates) and `vtctldclient.Proxy` (which proxies to Vtctlds).

In the original implementation, when calling `Dial` on one of these components, VTAdmin would use the Discovery implementation for that cluster to lookup a _single_ address, and call `grpc.Dial` to that address.
This works great for a proof-of-concept, but has several fundamental problems that would surface over time.

### Problem 1: Uneven Load

The model of `vtadmin-api`, by design, is to `Dial` a proxy to a VTGate or Vtctld the first time we need a connection to that component.
Then, in future `Dial` calls, the proxy sees it already has a connection; if it's still "healthy", we reuse the connection and return immediately.
But if the connection ever becomes "unhealthy", we throw it away, discover a new dial address, and make a new connection (see "Problem 2" for how this went in practice).

In effect, this meant that _for the life of the process_, VTAdmin would send **every single RPC** to a single host.
For small use cases, this is Fine&trade;, but it's certainly not great, and could knock over components at high enough usage.

Of course, you can spin up multiple `vtadmin-api` processes, and hope that they each pick a different gate, but the API is so lightweight that this feels like a very silly and unnecessarily expensive "solution."

### Problem 2: gRPC vs Proxies <!--done-->

By far the biggest issue with this approach happens when a VTGate or a Vtctld _goes away_.
Sometimes, there's network weather, and gRPC's `ClientConn` will internally handle the business of re-establishing a connection to the server, and we're all good.
The word "internally" there, though, is both a blessing and a curse.
You don't have to worry about &mdash; or manage &mdash; these details at all, but at the same time, gRPC[^2] exposes almost none of this to the end user of a `ClientConn`, no matter how much they legitimately need it.

Which makes extremely relevant the fact that both VTGates and Vtctlds are stateless components.
Stateless components are awesome!
You can put them in an auto-scaling group (ASG) and let your cloud provider make sure you have sufficient capacity, and cycle your hosts so they don't stick around forever.
You can easily implement a [blue-green deploy][bluegreen_deploy] mechanism based on setting the version you want to run and simply terminating hosts in the ASG.

And all of this is great, and will make your life as an operator simpler.
You'll also break VTAdmin.

You see, gRPC's "transient failure retry" mechanism can't, as far as I was ever able to observe, tell the different between network weather ("this host is gone for now, but it'll come back, just keep trying to reconnect") and more permanent failure ("this host has gone to a server farm upstate, you can try all you like but it's never coming back").
So, if VTAdmin had `Dial`-ed a Vtctld, and the ASG cycled it (or you did a deploy, or you manually terminated, or, or, or), the only way to get VTAdmin working again for that cluster is to completely restart the `vtadmin-api` process.

What we actually need is for VTAdmin to:

1. Realize the connection is gone and fully `Close` it.
2. Re-discover (via its `Discovery` implementation) a new host to dial and `grpc.Dial` that address.

But all we have is the sledgehammer of a full restart.
That's a big bummer, and also requires manual intervention.

We took a few attempts to [address][vtsql_ping] or [mitigate][vtctld_waitforready] this problem, which worked &hellip; well enough for an MVP, but they weren't perfect, and required our proxies to leak details about gRPC internals in some cases.

### Problem 3: We are Lying to You

I will admit this one is not a technical problem[^3], _per se_, but falls within my endless crusade of "words mean things."

`vtsql.DB` and `vtctldclient.Proxy` describe themselves _as proxies_.
And in one sense, they are &mdash; they _do_ sit between VTAdmin and another component, shuttling requests and responses back and forth.
But, they are the thinnest proxies imaginable.

They are really more of passthroughs than proxies, and, while having a passthrough is completely fine, and in many cases useful, _calling_ a passthrough a proxy is confusing at best, and might create false expectations from both users and developers.

## `grpc.Resolver` API

Luckily for us, gRPC has a (not widely-advertised[^4]) API to plug in your own mechanism for providing a list of addresses (a "resolver") to a client connection (a `ClientConn`).
gRPC will then use a second layer (a "balancer"; also pluggable, also not widely-advertised[^4]) to select one or more of those address to create actual, for-releasies `net.Conn` connections to (`SubConn`) and route RPCs to.

gRPC's defaults are to use a resolver called `passthrough`, and a balancer called `pick_first`.
The `pick_first` balancer (roughly) walks through the address list it gets from the resolver and creates a `SubConn` to the first address that successfully connects.
All future RPCs are sent to that `SubConn`.
You can also use a [service config][grpc_service_config] to specify other load balancer policies, like `round_robin`, which does what it sounds like.

But, we're not here to talk about balancers; we're here to talk about resolvers!
Here's what that `passthrough` resolver does[^5]:

```go
// internal/resolver/passthrough/passthrough.go

import "google.golang.org/grpc/resolver"

type builder struct {}

func (b *builder) Scheme() string { return "passthrough" }

func (b *builder) Build(target resolver.Target, cc resolver.ClientConn, opts resolver.BuildOptions) (resolver.Resolver, error) {
    cc.UpdateState(resolver.State{
        Addresses: []resolver.Address{{
            Addr: target.Endpoint,
        }},
    })
    return &passthrough{}, nil
}

type passthrough struct {}

func (r *passthrough) ResolveNow(o resolver.ResolveNowOptions) {}
func (r *passthrough) Close() {}

func init() { resolver.Register(&builder{}) }
```

There's a [builder pattern][builder_pattern] in play here.
gRPC expects you to specify a registry of `resolver.Builder` implementations, either in a global registry via `resolver.Register` and per-connection, with the dial option `grpc.WithResolvers(...resolver.Builder)`.
gRPC will determine the right kind of resolver to build for a given `ClientConn` at dial-time, based on the [naming scheme][grpc_naming][^6] of the dial target.
Dial targets are parsed as follows:

```
(<scheme>://)?(<authority>/)?<endpoint>
```

If a scheme is specified, then the `resolver.Builder` registered for that scheme is used; otherwise gRPC will fallback to its default `passthrough` resolver.
In addition, the parsed target gets passed to the `Builder.Build()` call, so the resolver can inspect its target if needed.

After building a resolver for the target, gRPC wraps the `ClientConn` a bunch, to make a nice burrito of a `grpc.ClientConn` inside a `balancer.ClientConn` inside a `resolver.ClientConn`[^7].
Then, for the life of the connection, gRPC will take different actions based on the connectivity state of the different `SubConn`s.
The details don't matter for our purposes, beyond "occasionally, _including on transient connection failures_, gRPC will request the resolver to re-resolve."
This is when `ResolveNow` gets called.

The contract here is that the resolver will then produce a new set of addresses, and communicate that back to the balancer via `cc.UpdateState`.
After its state is updated by the resolver, the balancer can then create/destroy/reuse `SubConn(s)` as it sees fit, and communicate this back to the `grpc.ClientConn` via its own `cc.UpdateState` method call.

---

_Phew_.

With all that preamble, let's return to the original problem.

VTAdmin has these thin proxies, which use a `Discovery` interface to discover a _single_ address to "proxy" to.
They don't distribute load over the N hosts that they _could_ have used, and furthermore have no way to inspect the connection state because that is internal to gRPC, so they can't discover different hosts on (permanent) "transient" failures.

But, if we use the resolver APIs, we can write our own resolver that uses our `Discovery` interface under the hood to look up the most up-to-date set of addresses whenever gRPC decides it needs to refresh the addresses for a dial target!
Then, balancing and connection management fall strictly under the purview of gRPC &mdash; which is more well-equipped to handle that anyway &mdash; and not VTAdmin.

Let's get into it.

## Implementation

[Here][vtadmin_custom_resolver_pr] is a link to the PR with the full implementation.
I've omitted some details for brevity and clarity.

### Devising a scheme

The first thing we need to do is figure out how to make gRPC use our resolver.
There's no way I could see to change the default resolver used by `grpc.Dial`, so we'll need to come up with our own URL scheme.

We also want to use different resolvers for different clusters (since each cluster has its own discovery implementation).
We already require clusters to have unique IDs, so we'll go ahead and just use the cluster ID as our scheme[^8].

Then, our `Dial`s go from using an `addr` that we get back from discovery to a somewhat magical string of `${clusterID}://${componentName}` (more on the component name in a bit).

We do need to thread the cluster's discovery through to the resolvers used by both Vtctld and VTGate proxies, like so:

```go
// go/vt/vtadmin/cluster/resolver/resolver.go
package resolver

import (
    "time"

    grpcresolver "google.golang.org/grpc/resolver"

    "vitess.io/vitess/go/vt/vtadmin/cluster/discovery"
)

type Options struct {
    Discovery        discovery.Discovery
    DiscoveryTags    []string
    DiscoveryTimeout time.Duration
}

func (opts *Options) NewBuilder(scheme string) grpcresolver.Builder {
    return &builder{
        scheme: scheme,
        opts:   *opts,
    }
}

// go/vt/vtadmin/vtctldclient/proxy.go (and similar for vtsql/vtgate)
func New(cfg *Config) *ClientProxy {
    vtctld := &ClientProxy{
        resolver: cfg.ResolverOptions.NewBuilder(cfg.Cluster.Id),
    }
}
```

This ensures that each proxy (I'm focusing on the Vtctld proxy, but the VTGate proxy is structurally identical) has a builder with the cluster ID as the scheme, as well as a reference to the `Discovery` implementation (via the `ResolverOptions`).
The builder will hand that Discovery to the actual resolver at build-time:

```go
func (b *builder) Build(target grpcresolver.Target, cc grpcresolver.ClientConn, opts grpcresolver.BuildOptions) (grpcresolver.Resolver, error) {
    var fn func(context.Context, []string) ([]string, error)
    switch target.URL.Host {
    case "vtctld":
        fn = b.opts.Discovery.DiscoverVtctldAddrs
    case "vtgate":
        fn = b.opts.Discovery.DiscoverVTGateAddrs
    default:
        return nil, fmt.Errorf("%s: unsupported URL host %s", logPrefix, target.URL.Host)
    }

	ctx, cancel := context.WithCancel(context.Background())

	r := &resolver{
        component:     target.URL.Host,
        cluster:       target.URL.Scheme,
        discoverAddrs: fn,
        opts:          b.opts,
        cc:            cc,
        sc:            sc,
        ctx:           ctx,
        cancel:        cancel,
        createdAt:     time.Now().UTC(),
    }
    r.ResolveNow(grpcresolver.ResolveNowOptions{})
    return r, nil
}
```

As you can see, we're abusing the URL `Host` fragment (formerly "authority" in the gRPC name resolution spec) to switch between Vtctld and VTGate components.
The only difference, functionally, is which discovery function we use, which gets set as the `fn` field in our built resolver.

Then, the underlying Dial in the Vtctld proxy becomes:

```go
dialOpts := append(vtctld.cfg.dialOpts, grpc.WithResolvers(vtctld.resolver))
cc, err := grpc.Dial(fmt.Sprintf("%s://vtctld/", vtctld.cfg.Cluster.Id), dialOpts...)
```

### ResolveNow

Perhaps the nicest thing about this change is, after all that convoluted preparatory work, the actual guts of the resolver is an almost verbatim copy of the discovery bits that were formerly in the body of the `Dial` methods of our proxies.
This time, instead of getting a single address and passing that to a `grpc.Dial` call, we instead get a _list_ of addresses, and inform the wrapped `ClientConn` of the new address set.
In code:

```go
func (r *resolver) ResolveNow(o grpcresolver.ResolveNowOptions) {
    state, err := r.resolve()
    if err != nil {
        r.cc.ReportError(err)
        return
    }

    err = r.cc.UpdateState(*state)
    if err != nil {
        r.cc.ReportError(err)
        return
    }
}

func (r *resolver) resolve() (*grpcresolver.State, error) {
    ctx, cancel := context.WithTimeout(r.ctx, r.opts.DiscoveryTimeout)
    defer cancel()

    // Reminder: discoverAddrs is one of discovery.Discover(Vtctld|VTGate)Addrs.
    // This was set in the `switch` block in builder.Build.
    addrs, err := r.discoverAddrs(ctx, r.opts.DiscoveryTags)
	if err != nil {
		return nil, fmt.Errorf("failed to discover %ss (cluster %s): %w", r.component, r.cluster, err)
	}

	state := &grpcresolver.State{
		Addresses: make([]grpcresolver.Address, len(addrs)),
	}

	for i, addr := range addrs {
		state.Addresses[i] = grpcresolver.Address{
			Addr: addr,
		}
	}

	return state, nil
}
```

And that's pretty much it!
This is a working implementation of a custom resolver, based on VTAdmin's cluster discovery interface.
It handles ASG-cycling gracefully, and I think it's pretty neat!

Everything else I want to talk about is extra considerations and future improvements.

### `debug.Debuggable`

VTAdmin aims to be operator-friendly, and to that end, it includes some debug endpoints to inspect the state of VTAdmin itself.
Here's how it works.

First, we define a very small interface that any debuggable component will implement:

```go
package debug

type Debuggable interface { Debug() map[string]any }
```

This interface is implemented by `*cluster.Cluster`, as well as the Vtctld and VTGate proxies.
VTAdmin then defines two http-only endpoints, `/debug/clusters/` and `/debug/cluster/${clusterID}`, whose handlers munge together all these maps into a JSON payload that operators can inspect.

Here's a subset, as an example:

```json
{
  "cluster": {
    "id": "local",
    "name": "local"
  },
  "config": {
    "ID": "local",
    "Name": "local",
    "DiscoveryImpl": "staticfile",
    "DiscoveryFlagsByImpl": {
      "staticfile": {
        "path": "./vtadmin/discovery.json"
      }
    },
    "TabletFQDNTmplStr": "{{ .Tablet.Hostname }}:15{{ .Tablet.Alias.Uid }}",
    "VtSQLFlags": {},
    "VtctldFlags": {},
    "BackupReadPoolConfig": null,
    "SchemaReadPoolConfig": null,
    "TopoRWPoolConfig": null,
    "TopoReadPoolConfig": null,
    "WorkflowReadPoolConfig": null
  },
  "pools": {
    "backup_read_pool": {
      "Capacity": 500,
      "Available": 500,
      "Active": 500,
      "InUse": 0,
      "MaxCapacity": 500,
      "WaitCount": 0,
      "WaitTime": 0,
      "IdleTimeout": 0,
      "IdleClosed": 0,
      "Exhausted": 0
    },
    "schema_read_pool": {
      "Capacity": 500,
      "Available": 500,
      "Active": 500,
      "InUse": 0,
      "MaxCapacity": 500,
      "WaitCount": 0,
      "WaitTime": 0,
      "IdleTimeout": 0,
      "IdleClosed": 0,
      "Exhausted": 0
    }, // more pools elided
  },
  "vtctld": {
    "dialed_at": "2022-04-15T11:31:14-04:00",
    "is_connected": true
  },
  "vtsql": {
    "dialed_at": "2022-04-15T11:31:14-04:00",
    "is_connected": true
    }
  }
}
```

Prior to the custom resolver, the proxies used to track which host they were connected to, as well as the last time they pinged that host as a crude healthcheck.
The resolver vastly improved the stability of the API process, but as a result the discovery all happens in the background, completely opaquely to the proxies.
This meant we lost that small, but useful, piece of introspection.

That's okay though!
If you recall back to how the proxies hook themselves into the resolver builders, they actually maintain a reference to the builder for that cluster scheme:

```go
func New(cfg *Config) *ClientProxy {
    vtctld := &ClientProxy{
        resolver: cfg.ResolverOptions.NewBuilder(cfg.Cluster.Id),
    }
}
```

This means that if we have our builder also implement `debug.Debuggable`, then we can update each proxy's `Debug()` method to merge those maps in to the final JSON payload.
And that's exactly what we do:

```go
// Debug implements debug.Debuggable for builder.
func (b *builder) Debug() map[string]any {
    // I didn't show you this, but we also have the builder track the list of
    // resolvers it's built, in order to support this.
	resolvers := make([]map[string]any, len(b.resolvers))
	m := map[string]any{
		"scheme":            b.scheme,
		"discovery_tags":    b.opts.DiscoveryTags,
		"discovery_timeout": b.opts.DiscoveryTimeout,
		"resolvers":         resolvers,
	}

	for i, r := range b.resolvers {
		resolvers[i] = r.Debug()
	}

	return m
}

// Debug implements debug.Debuggable for resolver.
func (r *resolver) Debug() map[string]any {
	m := map[string]any{
		"cluster":    r.cluster,
		"component":  r.component,
		"created_at": debug.TimeToString(r.createdAt),
		"addr_list":  r.lastAddrs,
	}

	if !r.lastResolvedAt.IsZero() {
		m["last_resolved_at"] = debug.TimeToString(r.lastResolvedAt)
	}

	if r.lastResolveError != nil {
		m["error"] = r.lastResolveError.Error()
	}

	return m
}
```

_Now_[^9], hitting the `/debug/` endpoint for that cluster shows the resolver states:

```json
{
  "cluster": {...},
  "config": {...},
  "pools": {...},
  "vtctld": {
    "dialed_at": "2022-04-15T11:31:14-04:00",
    "is_connected": true,
    "resolver": {
      "discovery_tags": null,
      "discovery_timeout": 100000000,
      "resolvers": [
        {
          "addr_list": [
            {
              "Addr": "localhost:15999",
              "ServerName": "",
              "Attributes": null,
              "BalancerAttributes": null,
              "Type": 0,
              "Metadata": null
            }
          ],
          "cluster": "local",
          "component": "vtctld",
          "created_at": "2022-04-15T15:31:14Z",
          "last_resolved_at": "2022-04-15T15:31:48Z"
        }
      ],
      "scheme": "local"
    }
  },
  "vtsql": {
    "dialed_at": "2022-04-15T11:31:14-04:00",
    "is_connected": true,
    "resolver": {
      "discovery_tags": null,
      "discovery_timeout": 100000000,
      "resolvers": [
        {
          "addr_list": [
            {
              "Addr": "localhost:15991",
              "ServerName": "",
              "Attributes": null,
              "BalancerAttributes": null,
              "Type": 0,
              "Metadata": null
            }
          ],
          "cluster": "local",
          "component": "vtgate",
          "created_at": "2022-04-15T15:31:14Z",
          "last_resolved_at": "2022-04-15T15:31:48Z"
        }
      ],
      "scheme": "local"
    }
  }
}
```

Of course, all we can provide is the list of _potential_ addresses; which one(s) gRPC has connection(s) to depends on the balancer policy used.
Still, it's better than nothing, and I think the tradeoff of debuggability for reliability is worth it.

## Future Work

While this is stable and working now, I also studied the implementation of the [`dns` resolver in grpc-go][grpc_go_dns_resolver].
Two things jumped out to me:

1. The resolver continuously (on an interval) re-resolves the target [in a background goroutine][grpc_go_dns_resolver_watcher], and uses its `ResolveNow` method _only_ to jump the interval wait time and trigger a re-resolution immediately.
    1. (It's not strictly "immediate", because it also enforces a minimum, non-configurable 30s wait between DNS lookups ["to prevent constantly re-resolving"][grpc_go_dns_resolver_min_wait]).
2. It [uses a backoff mechanism][grpc_go_dns_resolver_backoff] to try to re-resolve when a DNS lookup fails, or if the call to `cc.UpdateState` fails, which can help in transient failure modes.

I want both of these things for our discovery resolver, as I think they'll have a significant impact on reliability.
What I'd _really_ like is for `grpc-go` to expose a different interface API that provides the scaffolding of "background loop" + "(configurable) min-wait" + "backoff on failure" + "update state or report error", and you, as the consumer of this API provide a function that takes a `resolver.Target`, `resolver.BuildOptions`, and `resolver.ResolveNowOptions` and returns a `(*resolver.State, error)`.
Failing that, I'll just have to copy-paste the guts of the DNS watcher loop and replace the `d.lookup()` call with our `r.resolve()` method.

[^1]: You can see me give an overview of VTAdmin at KubeCon 2021 [here][vtadmin_kubecon_talk].
[^2]: I'm referring to `grpc-go` specifically here (and throughout the post), since Vitess, and by extension, `vtadmin-api` are written in Go. Different languages may have implementations that differ on this point.
[^3]: More accurately: it's more of a semantic issue than a technical problem, and the technical problems that _do_ lie within the semantic issue are covered by the other problems discussed prior.
[^4]: In my opinion, which you are free to disagree with.
[^5]: This is not the actual code, which I have modified for both brevity and clarity.
[^6]: These docs are not actually accurate for `grpc-go`, which [defaults to the `passthrough` resolver][grpc_go_default_resolver] I've been showing here. Of course, this ends up using various `net.Lookup` calls to turn non-IP addresses into IPs, but this happens during the creation of the HTTP transport, _not_ at resolver-time. There's _also_ a [`dns` resolver][grpc_go_dns_resolver] which does this at resolver-time and hands IP addresses back to the balancer.
[^7]: Or maybe it's a [conn-ducken][turducken].
[^8]: In the spirit of completeness, since we are using the connection-local registry, we actually don't have to care about cross-cluster uniqueness in the URL scheme. We could instead have just used a scheme such as `vtadmin://` everywhere, but I didn't, so here we are.
[^9]: There's code changes required in the proxies that aren't very interesting. The one thing to note is that because we don't export the resolver type (because I wanted to have the proxies store an interface type, to support dependency injection for testability), we have to make a type assertion before adding the debug info. [Here][vtctldclient_proxy_debug] is the Vtctld version.

[vtadmin_rfc]: https://github.com/vitessio/vitess/issues/7117
[vtadmin_kubecon_talk]: https://youtu.be/uKdMR89mfdE?t=1014
[vtadmin_custom_resolver_pr]: https://github.com/vitessio/vitess/pull/9977

[bluegreen_deploy]: https://martinfowler.com/bliki/BlueGreenDeployment.html
[builder_pattern]: https://en.wikipedia.org/wiki/Builder_pattern
[turducken]: https://en.wikipedia.org/wiki/Turducken

[vtsql_ping]: https://github.com/vitessio/vitess/pull/7709
[vtctld_waitforready]: https://github.com/vitessio/vitess/pull/9915
[vtctldclient_proxy_debug]: https://github.com/vitessio/vitess/blob/ef7363e918e5c7093d72f15471f4c0d408ac0d10/go/vt/vtadmin/vtctldclient/proxy.go#L178-L204

[grpc_service_config]: https://github.com/grpc/grpc/blob/master/doc/service_config.md
[grpc_naming]: https://github.com/grpc/grpc/blob/master/doc/naming.md
[grpc_go_default_resolver]: https://github.com/grpc/grpc-go/blob/3bf6719fc8ab5dac43b8494fcdc7e892efde6ea1/clientconn.go#L1574-L1578
[grpc_go_dns_resolver]: https://github.com/grpc/grpc-go/blob/3bf6719fc8ab5dac43b8494fcdc7e892efde6ea1/internal/resolver/dns/dns_resolver.go
[grpc_go_dns_resolver_watcher]: https://github.com/grpc/grpc-go/blob/3bf6719fc8ab5dac43b8494fcdc7e892efde6ea1/internal/resolver/dns/dns_resolver.go#L152-L154
[grpc_go_dns_resolver_min_wait]: https://github.com/grpc/grpc-go/blob/3bf6719fc8ab5dac43b8494fcdc7e892efde6ea1/internal/resolver/dns/dns_resolver.go#L223-L224
[grpc_go_dns_resolver_backoff]: https://github.com/grpc/grpc-go/blob/3bf6719fc8ab5dac43b8494fcdc7e892efde6ea1/internal/resolver/dns/dns_resolver.go#L234-L235
