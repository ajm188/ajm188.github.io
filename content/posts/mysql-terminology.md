---
title: "Database Terminology"
date: 2020-06-20T16:30:46-04:00
draft: true
---

This is an elaboration on/restructuring of a
[twitter thread](https://twitter.com/andrew_mason1/status/1272363491979132928)
I wrote on Sunday, June 14th.

---

Hey devs, I'm all with you on renaming the primary git branch to main/canon/primary,
but don't forget about the databases. They're almost as widely used as version control,
and all of the major ones use master/slave as a core concept in production setups.

Here's what you can do:

### Fix your things

If you have tools for managing or inspecting a database cluster, wrap them in
tooling that uses the terminology you prefer (I like primary/replica). Push the
master/slave as far down to the database as you can. Don't force your employees
to be steeped in it. For example, on Friday[^1] I gave us `show-replication-status`
to replace `show-slave-status` among many others. You probably have some
documentation about your databases, and runbooks for them when they page. Update those.

### Fix our things

If you use a database that's open source, submit PRs to change these terms.
If you use a proprietary database, wait until the end of this thread[^2].

When you submit or push for changes in open source, you'll get people telling
you to leave politics out of it. Ignore them. Code is political.

You'll also get people telling you it's too complicated, that it's too core to
the database to think about fundamentally changing at this point. This is
half true. It is both core and complicated. That doesn't mean it can't or
shouldn't be done. Changing this is the same as changing any other public API:
1. Add a new API that has the same behavior as the old API.
1. Make the new API the default, mark the old API as deprecated.
1. Delete the old API.

For example, update the parser to accept `SHOW REPLICATION STATUS`, and have it
call into the same function as the command it's aiming to replace. Do this for every
command, user privilege, and system variable/table. You don't have to do them
all yourself. Start with one and others will help. I will help. When this has
been completed for every public-facing component, this is a *huge win*.
You have now reduced the number of people who must work with master/slave
terminology from "anyone that works with databases" to "anyone that works on
database source code."

The other thing this unlocks is that the internals no longer depend on or are coupled to those words being in the public API. The internals can get changed behind the scenes at a careful pace without causing breaking changes. If you use a proprietary database, get your company to put pressure on that proprietor. Get other users to pressure. Develop a real plan to migrate your data if they won't. Unless you can commit to leaving their technology, your pressure doesn't mean very much. If you use MySQL, guess what? That's owned by Oracle. That's who you want to talk to. If they won't budge, switch to percona's MySQL. Maybe you can get one to budge. If not, MySQL is technically open-source. We as a community can fork it.

### Get Them to Fix Their Things

[^1]: June 12th
[^2]: As I started writing this post, I realized I never explicitly
returned to this point, instead getting distracted by the semi-open source
nature of MySQL. Oops. At least I can fix that now.
