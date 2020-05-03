---
title: "Rails, Travis-CI, and Factory Girl"
date: 2015-04-18T13:00:31-04:00
draft: false
tags:
- ruby
- rails
- travis
- factory girl
---


I spent the better part of tonight trying to debug getting
[Travis-CI](https://travis-ci.org/) set up on a repository I'm
working on, so I thought I'd write up what the problem was, and hopefully
that may eventually help someone else not go through the same headaches.

[This gist](https://gist.github.com/ajm188/86fd587c9fc30a4d5d38)
was the original error I was trying to debug. See line 503 of log.txt for
the postgres error.

Before I begin explaining the problem, the fix is to change the Gemfile:

```ruby
# Gemfile (original)
gem 'factory_girl_rails'

# Gemfile (fix)
gem 'factory_girl_rails', require: false
```

### The Problem

Without the `require: false`, FactoryGirl gets loaded when the
`rake environment` task is run. Without any schema loaded in the
database (which is true on every Travis run), there are no relations
defined until `rake db:migrate` completes. However,
`rake db:migrate` depends on `rake environment`.

This means, when we do `rake db:migrate`, FactoryGirl gets
loaded, and tries to figure out all of the factory definitions, which don't
exist until `rake db:migrate` completes. Whoops.

### The Fix

First, change your Gemfile to not require FactoryGirl by default, as noted
above. Then, in your rails_helper.rb, and also env.rb (for cucumber):

```ruby
require 'factory_girl_rails'
```

This delays the loading of FactoryGirl until your specs/tests/features are run,
so your database migrations can run correctly and without error on the Travis
server.
