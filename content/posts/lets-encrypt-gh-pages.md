---
title: "Let's Encrypt This Blog"
date: 2017-03-13T16:54:35-04:00
draft: false
subtitle: Setting Up HTTPS on GitHub Pages
tags:
- "lets encrypt"
- github
- nginx
---
<span>

## Disclaimer

First things first, I need to tell you something.
For most use cases, the following is going to be unnecessary.
If all you want is a blog with the green padlock, maybe with a custom domain, and you're not a masochist, this post is likely useless to you.
GitHub pages gives you HTTPS for free.
Spend your time reading something more valuable.

## Initial Setup

However, I am a masochist.
Or, maybe I'm thinking ahead to future use cases.
I have a [DigitalOcean][do_referral] droplet (yes, that's my referral link) which runs an [nginx][nginx] reverse proxy.
The droplet lives at [fixedpoint.xyz](https://fixedpoint.xyz).
I also have a CNAME pointing [www.fixedpoint.xyz](http://www.fixedpoint.xyz) to my GitHub pages domain (that is, [ajm188.github.io](http://ajm188.github.io)).

Why would I do something like this?
Because I can.
Also, I could in theory add dynamic content to my site, while still having GitHub serve all the static content.
All it would take is a service running on the droplet and a small tweak to the nginx config.
Speaking of, my nginx config at this point looked something like:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name fixedpoint.xyz;

    location ~ /(.*) {
        resolver 127.0.0.1;
        proxy_pass http://www.fixedpoint.xyz/$1$is_args$args;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Host $server_name;
    }
}
```

### What's with the resolver line?

Good question.
That tells nginx to talk to my local `dnsmasq` to get the IP address of www.fixedpoint.xyz.
GitHub doesn't guarantee that your Pages site will stay at a fixed IP forever.
That would be bad.
GitHub does some fancy magic on their end to move your site around as dictated by the needs of their infrastructure.
So, we need nginx to reresolve the DNS entry whenever GitHub moves your site.

## Let's Encrypt!

### Getting Started

Time to get started.
[Let's Encrypt][lets_encrypt] provides a "Getting Started" guide.
This points you to the [certbot][certbot] website, which instructs you to specify various parts of your tech stack.
In my case, I ended up [here][certbot_nginx_xenial].
I decided to use the webroot plugin, rather than "standalone" instructions.
The webroot instructions seemed far simpler.
So, I did:

```bash {linenos=false}
letsencrypt certonly --webroot -w /var/www/fixedpoint -d fixedpoint.xyz -d www.fixedpoint.xyz
```

And it failed!

`letsencrypt` was complaining about the `/var/www/fixedpoint` directory not existing.
No problem.
After making the missing directory, I reran the `letsencrypt` command.

And it failed again!

### Whose Domain is it Anyway?

This time the problem looked something like the following.
Note that I grabbed this from google, since I didn't capture the error message at the time.
I did change the domains to reflect my actual domain and subdomain, though.

```
Failed authorization procedure. fixedpoint.xyz (http-01):
    urn:acme:error:unauthorized ::
    The client lacks sufficient authorization ::
    Invalid response from http://fixedpoint.xyz/.well-known/acme-challenge/789[...]eSA [255.255.255.255]: 404

Failed authorization procedure. www.fixedpoint.xyz (http-01):
    urn:acme:error:unauthorized ::
    The client lacks sufficient authorization ::
    Invalid response from http://www.fixedpoint.xyz/.well-known/acme-challenge/789[...]eSA [255.255.255.255]: 404

IMPORTANT NOTES:
 - The following 'urn:acme:error:unauthorized' errors were reported by
   the server:

   Domains: fixedpoint.xyz www.fixedpoint.xyz
   Error: The client lacks sufficient authorization
```

What's going on here?
Well, you can't get a cert for just any old domain.
You can only get one for a domain that you actually own!
Makes sense to me.

Turns out this "acme challenge" thing is one way to prove you own a domain.
After a bit of googling, I settled on the following nginx config:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name fixedpoint.xyz;

    root /var/www/fixedpoint;

    location ~ /.well-known/acme-challenge/(.*) {
        allow all;
    }

    location ~ /(.*) {
        resolver 127.0.0.1;
        proxy_pass http://www.fixedpoint.xyz/$1$is_args$args;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Host $server_name;
    }
}
```

We made a couple of notable changes here.

* `root /var/www/fixedpoint;`
    * This tells nginx to consider `/var/www/fixedpoint` the root directory for this server.
      So, by default, if we requested say "/blah", nginx would look up `/var/www/fixedpoint/blah`.
      Of course, with the `location ~ /(.*)` block, we currently override this by proxying to the `www` subdomain.
* `location ~ /.well-known/acme-challenge/(.*)`
    * This block (when it contains `allow any;`) tells nginx to let any IP address poke around at URLs matching the regex.

When nginx handles a request, it will go through the various `location` blocks for a server from top to bottom, picking the first one that matches.
So, putting these two changes together means that a request to `http://fixedpoint.xyz/.well-known/acme-challenge/blah` will trigger nginx to look for `/var/www/fixedpoint/.well-known/acme-challenge/blah` and return a 200.

### Giving Up on `www`

So now we rerun the `letsencrypt` command from above.
It fails.
Womp womp.

However, the error message is smaller!
Now I'm looking at:

```
Failed authorization procedure. www.fixedpoint.xyz (http-01):
    urn:acme:error:unauthorized ::
    The client lacks sufficient authorization ::
    Invalid response from http://www.fixedpoint.xyz/.well-known/acme-challenge/789[...]eSA [255.255.255.255]: 404

IMPORTANT NOTES:
 - The following 'urn:acme:error:unauthorized' errors were reported by
   the server:

   Domains: www.fixedpoint.xyz
   Error: The client lacks sufficient authorization
```

Looks like it worked for the root domain, but we still can't handle the `www` subdomain.

Ohhhhh, right.
That's because my DNS CNAME points `www` to my GitHub Pages domain.
There's no `/.well-known/acme-challenge` directory in my Pages repository.
So of course it doesn't work.
I solved this by (temporarily (?)) giving up on encrypting the `www` subdomain.
In fact, as of writing this, if you visit https://www.fixedpoint.xyz/ you'll see that scary "YOUR CONNECTION IS NOT SECURE," assuming your browser cares about your safety.

### Redirect Me, Please

Next up, we need nginx to take incoming http requests and send back a 301 redirect to https.

### Encrypted Roots

First up (after a fair amount of googling), I tried the following nginx config:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name fixedpoint.xyz;

    root /var/www/fixedpoint;

    location ~ /.well-known/acme-challenge/(.*) {
        default_type "text/plain";
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name fixedpoint.xyz;

    ssl on;
    ssl_certificate /etc/letsencrypt/live/fixedpoint.xyz/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fixedpoint.xyz/privkey.pem;

    location ~ /(.*) {
        resolver 127.0.0.1;
        proxy_pass http://www.fixedpoint.xyz/$1$is_args$args;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Host $server_name;
    }
}
```

This mostly works!
We now have two nginx servers.

The first listens on port 80 for HTTP.
It takes any request (except those going to `/.well-known/acme-challenge/blah`) and returns a 301 redirect to the HTTPS version of the URL.

The second listens on port 443 for HTTPS.
It does the usual proxying to the `www` subdomain.
This eventually ends up at the GitHub Pages address, like before.

Visiting https://fixedpoint.xyz works!
Even better, visiting http://fixedpoint.xyz redirects me to HTTPS, as it should!
Woohoo!!!

### Encrypt It All

What's the problem?
Remember how we didn't get a cert for the `www` subdomain?

I clicked on "/blog".
I got proxied to http://www.fixedpoint.xyz/blog.

Noooooooooooo!!!!!!!!!!!![^1]

This one took me over an hour to solve.
I must admit, I had not spent that much time with nginx configurations before, so I had limited knowledge.
But, the internet's knowledge is boundless!

Hilariously - but also a bit frustratingly - all it took was a single line added to the proxying instructions:

```nginx
server {
    # ssl stuff

    location ~ /(.*) {
        # other proxy stuff
        proxy_redirect http://www. https://
    }
}
```

This works!
When a request goes out, nginx will strip the "http://www." off the beginning and replace it with "https://".
Now I don't get redirected to `www` when I click on "/blog"!

So the final config looks like:

```nginx
server {
    listen 80;
    listen [::]:80;

    server_name fixedpoint.xyz;

    root /var/www/fixedpoint;

    location ~ /.well-known/acme-challenge/(.*) {
        default_type "text/plain";
    }

    location / {
        return 301 https://$host$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name fixedpoint.xyz;

    ssl on;
    ssl_certificate /etc/letsencrypt/live/fixedpoint.xyz/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/fixedpoint.xyz/privkey.pem;

    location ~ /(.*) {
        resolver 127.0.0.1;
        proxy_pass http://www.fixedpoint.xyz/$1$is_args$args;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Host $server_name;
        proxy_redirect http://www. https://
    }
}
```

### The Machines Take Over

There's only one thing left to do.
My cert will expire in June, which means I need to remember to log back in to my droplet and generate a new cerrt before then.
This is done by running `letsencrypt renew`.

Just kidding! - at least about the "logging back in" bit.
I don't want to have to remember to do that.
I'll almost surely forget.
Let's automate with [cron][cron]!
Simply add the following to your crontab:

```cron
@monthly letsencrypt renew
```

The `renew` command is idempotent, which means we can run it more often than we need to.
This ensures I'm covered in case the command fails - it will run the next month, still before my cert expires.
I could run it every second if I wanted to, but be kind to others - especially people that issue free SSL certs.

## The End

What a tale!
I hope you learned something.
If you see anything wrong with my setup, please let me know!
I'm thinking next I'll point `www` at my droplet and get a cert for that subdomain as well.
That will have to wait until I get some more free time, though.

[do_referral]: https://m.do.co/c/65ed942945d1
[nginx]: https://www.nginx.com
[lets_encrypt]: https://letsencrypt.org/getting-started/
[certbot]: https://certbot.eff.org
[certbot_nginx_xenial]: https://certbot.eff.org/#ubuntuxenial-nginx
[cron]: https://en.wikipedia.org/wiki/Cron

[^1]: http://www.nooooooooooooooo.com/
