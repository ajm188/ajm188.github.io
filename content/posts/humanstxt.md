---
title: "humans.txt"
date: 2022-12-21T06:36:44-05:00
draft: true
---

I just added a [humans.txt] file to this site.

I learned about this idea a few weeks back and really liked it!
It's simple, it's plaintext, and it spits in the face of the subtext of `robots.txt` being "the internet is for robots (and not for humans)."

You can read more about it [here][humanstxt.org].

## Implementation Details

Initially, I tried to "just" make a `Page` at the top-level of my content (similar to how my [about page]) is generated, but have `hugo` produce a text file instead of HTML.

Once I got the output format hooked up[^1], I was off to the races ... _except_ ... it looked (literally) like this:

```
Last update: {{ now.UTC.Format "2006/02/01 15:04:05 MST" }}
```

_Shoot,_ I thought, _can I only have template directives render when outputting HTML files?_
I really wanted this line in particular to render so I didn't have to remember to update the date every time I pushed changes.

Many, _many_ hours of random googling and "what about _this_ random configuration tweak?" later, I realized that if I put all the templating in the layout file instead of directly in the content file, then it would work.

In fact, as I began writing this post, I attempted (and failed) to use a `{{ ref }}` directive.
It occurs to me that template directives may only be possible in layout files, full stop, and that it's simply been so long since I've done much writing here that I've forgotten, if I ever knew that to begin with.

### Weird and Gross&trade;

Now, because I moved some of the rendering from the content to the layout, I was now in a situation where my layout needed to render, in _rough_ pseudocode:

```
{{ render stuff-before-LastUpdated-in-content-file }}
Last update: {{ now.UTC.Format "2006/02/01 15:04:05 MST" }}
{{ render stuff-after-LastUpdated-in-content-file }}
```

which is ... Weird and Gross&trade;.

### Data Files

My next idea, then, was to move _all_ of the `humans.txt` metadata into frontmatter, and create a dedicated page type that whose layout would render entirely from frontmatter.
That looks like [this][humans_frontmatter_pre_datafiles], and it totally works!

The downside here is my content file is now (in theory) an ever-growing frontmatter document with no actual content in it.
Which is Weird and Gross&trade;, but in a different way.

Then I stumbled onto [data files], which

> are not for generating standalone pages. They should supplement content files by ... extending the content when the front matter fields grow out of control

Well, well, well! If that isn't exactly the problem I'm trying to solve!

So, now my `layouts/humans/single.txt` renders data from three files:

| File | `humans.txt` Section |
|-|-|
| `data/humans/team.yaml` | `/* TEAM */` |
| `data/humans/thanks.yaml` | `/* THANKS */` |
| `data/humans/site.yaml` | `/* SITE */` |

Much nicer!

[^1]: Adding [this](https://github.com/ajm188/ajm188.github.io/blob/4970387a3d1b25f5cc67162012b4b981220613c0/config.toml#L6-L10) to `config.toml` and dropping a template in `layouts/page/single.txt` got me past `found no layout file "txt" for kind "page"`.

[humans.txt]: /humans.txt
[humanstxt.org]: https://humanstxt.org
[about page]: /about
[humans_frontmatter_pre_datafiles]: https://github.com/ajm188/ajm188.github.io/blob/74bb7fcddf8890975eaf37077e715ac6551ac0d4/layouts/humans/single.txt
[data files]: https://gohugo.io/templates/data-templates/
