---
title: "HackCWRU '16 Wrap Up"
date: 2016-02-14T20:00:18-04:00
draft: false
tags:
- hackathon
- cwru
- hacsoc
---

Well, I finally got back to my dorm from helping clean up
HackCWRU. They ~~let me~~ made me leave early, since I had not slept all
night. As the ever-loving Dave put it, "the more tired you become, the more
belligerent you are about how you're not being annoying, which is annoying
in and of itself." Sorry, Dave. I could have sworn I was acting normally.

In my sleep-deprived state, I am going to try to reflect on my experiences
at the hackathon. I'm really tired, but it's probably better to write down
my thoughts while everything is still fresh in my mind. Please bear with me
through the inevitable typos, along with the sentences that will make
absolutely no sense because I have become delirious. Hopefully,
`flyspell-mode` will catch the spelling errors. For the grammar,
I appear to be up a creek without a paddle.

## The Hackathon

Things got off to a bit of a rocky start, but quickly smoothed out. There
were a few hiccups, like one of our breakfast meals being delivered a day
early, or getting delivered monitor stands in lieu of the power strips we
ordered, but we were able to push through all of them (as far as I could
tell). We'll get to go over all the wins and bumps in our postmortem this
week. We've started to make a habit of having a postmortem after our bigger
events (the other being [Link State](http://acm.case.edu/acm/conference)
in the Fall) to get all the lessons we learned down in writing while they
are still fresh in our minds. This has been an incredibly valuable thing
for us to do, since we end up with a checklist of do's and don'ts to
reference when we plan for next year, and we avoid re-learning the same
lessons over and over.

### Taking a Back Seat

Since I somehow became part of the "old guard", this year I took much more
of a back seat role in helping run the event. Often, I felt out of the loop
of what was actually going on at the hackathon. This resulted both from my
occasional failure to keep up with the communication stream, but also
simply resulting from the fact that I wasn't always around where the
"action" was happening. I (happily and willingly) stayed behind during
opening ceremonies to staff the outer check-in booth, and I stayed behind
again to start the clean-up (with assistance from **awesome** alumni and
volunteers) during the closing ceremonies. Oftentimes, a hacker would
approach me with a question, and I would have absolutely no idea how to
answer her question - I either had to ask a nearby volunteer, or turn to
our Slack.

Taking a step back from the action allowed me to get a higher-altitude view
of what running a hackathon involves and can do to the organizers. The
obvious place to start here is stress. Running a hackathon takes an
incredible toll on the organizers and can push their stress-tolerance to
its limits. However, I noticed that often this stress is self-imposed. I
don't mean to say that it's all in their heads, but I do see smaller
stresses become amplified in the heat of the moment. I think that taking a
moment to step back and ask yourself "is it _really_ a big deal if
the food isn't ready until 7:03, even though the schedule clearly has
dinner at 7:00 sharp?" goes a long way to keeping your blood pressure
down.

In the wise words of Dave, our wonderful alum and hackathon veteran who for
some reason keeps coming back to help us out (we love you, Dave), "the key
to running these things smoothly and stress-free is to not give a shit. You
can plan all you like, but something **will always go wrong**, and you need
to take that in stride and not worry about it." I may not have been the one
to say it, but I wholeheartedly agree, and I watched this happen time and
again throughout the weekend.

Taking a back seat had another perk as well. Not spending my time running
around like a headless chicken gave me the opportunity to participate in
more of the actual events of the hackathon. I was able to actually work on
projects and join in on a meditation session (which was awesome, by the
way).

### Endorse Me for DJ-ing on LinkedIn!

In addition to working on my own projects and taking part in an awesome
meditation session, Dina forced my hand into being the DJ for the
late-night dance competition on Saturday. I really wanted to go home to go
to bed (I originally planned on leaving around 11:00 PM, and the dance-off
didn't start until after midnight. Ugh, that's sooooo late.), but I was the
only person around willing to stick my laptop into the speaker for an
hour. We frantically threw together a playlist of "probably pretty popular"
songs that "people probably like to dance to." In my haste, I accidentally
ended up grabbing weird remixed versions of songs that were mostly really
bad. The dance floor let me know which songs to skip with their kind
booing, but soon I got pretty invested into my role as dance-floor DJ and
had a lot of fun doing it. I laid down some "ill" beats, until the play
queue finally devolved into all of my favorite 90s tunes: "Bye Bye Bye,"
"Baby One More Time," ... you get the idea. Very much against my original
plans, I DJ-ed until past 1:00 AM.

### The Hour Gets Late and Everything Else Gets Weird

Two hours after I planned to leave, I was still
in [think[box]](http://engineering.case.edu/thinkbox/). By this
time, the temperature had dropped to a frigid four degrees, completely
destroying any desire I still had to walk to my car. Sometime within the
next hour, I made up my mind I would be staying the night. I hunkered down
and got back to the project I was working before I stopped to
DJ. Admittedly, I can't recall in great detail what actually happened in
the early hours of this morning, but things definitely got very weird, and
got weird at a rapidly accelerating rate. However, I solemnly swear that
the following events did indeed occur.

**I spent a horrible amount of time writing fish**. Ordinarily, I love my
[fish shell](http://fishshell.com), but sorting out fish-specific issues late into the night quickly
became increasingly frustrating. Luckily, I stuck it out
and [this pull request](https://github.com/zquestz/s/pull/91) is the final result. The overall eighty-three
lines[^1] add some pretty cool completions for
the <code>s</code> utility in fish. Go voice your opinion if you want to
see the PR merged!

**Stephen wrote a horrible amount of JavaScript**. [Stephen](http://stephen-brennan.com) had
the brilliant (for some definition of brilliant) idea to spend the night
writing his [regular expression library](https://github.com/brenns10/regex) (originally in C) in JavaScript. Now, Stephen spends much more
time in languages like C than in
the [young, wild and free](https://youtu.be/Wa5B22KAkEk)
languages like JavaScript, so he was bound to encounter some turbulence, at
least early on. I don't mean to offend (he was laughing just as much as I
was at the time), but it seemed that the act of Stephen fighting with
JavaScript was about as entertaining as the act of me fighting with
fish. As a matter of fact, this happened:

{{< tweet 698764609747034113 >}}

These memories are some of my favorite from the entire hackathon. Even
though I got hopped up on energy drinks and junk food and completely
neglected my physical health for the entire night, getting to spend time
with good friends of mine and deliriously working our way through problems
together while jamming out to Taylor Swift was both incredibly hilarious
and incredibly rewarding.

**Things happened on Twitter**. First, I lost all faith in the
idea that computers were logical machines that performed exactly the set of
instructions they were programmed with in the exact order the instructions
were specified:

{{< tweet 698646325097840640 >}}

Then, TCP handshakes somehow became risque:

{{< tweet 698770343926878208 >}}

Next, my mind, in its descent into madness, became self-aware:

{{< tweet 698771587072442368 >}}

Then, there was a snack-based rebellion among the hackers, led by the
self-appointed "Bernie Snackers", which led to a pun-infused retweet stack
(seriously, follow this one all the way down. The original protest is
incredible):

{{< tweet 698773020010225664 >}}

**We called [Steph](http://stephhippo.com/)**. She "had to be in Seattle for
work," and we didn't want her to miss out. She quickly became concerned about
our health and sanity, but was too entertained by the ludicrousness of it all
to make a serious attempt to corral us.

**I figured out my MATLAB homework**. We were working with
images, since matrix manipulation seems to be one of the only things MATLAB
is good for, though I still argue that NumPy works just fine. The code to
grayscale the image simply would not work; the end result was a tiny blob
of unintelligible pixels surrounded by a sea of white. Given that
grayscaling was such a simple technique, I was thoroughly baffled and
quickly became stumped. Finally, in a moment of "what the hell; I've tried
everything else, might as well give this a shot," I removed a single
typecast that the homework document _told us was necessary_ and the
code immediately worked with no further changes. I quickly reverted to my
earlier state of "how do computers even work."

### The Endless Night Ends

Deep in sleep deprivation, I stopped being able to interpret time
correctly. Time passed both exceedingly slowly and rapidly
simultaneously. I would work for what felt like hours on a problem and look
up to find that only ten or fifteen minutes had passed. Other times we
would cackle maniacally about something which was definitely Not Funny, and
an hour would go by.

So, bringing with it both great relief and great surprise, our all-nighter
finally came to an end. Morning had come. Zach and I ran off to Starbucks to
pick up a large coffee order we placed. There, we learned that we had purchased
ten gallons of coffee. In case you are wondering how much coffee ten gallons of
coffee actually is, it's **a lot** of coffee. We also learned that bulk coffee
at Starbucks runs at $18 per gallon, so think about that the next time you
complain about gas  prices.

At any rate, HackCWRU went on. We served breakfast - Zach and I returned
with the coffee just in time. The hackers submitted their projects and
waited for judging and closing ceremonies to begin. I elected to stay
behind during the judging and other events to start the clean-up efforts. I
was beyond tired and, as much fun as I had, wanted to get home and go to
sleep. A few other volunteers stayed behind with me to jump-start the
cleaning as well. So, while we cleaned, I got to spend time catching up with
Dave, who I had not seen since the last time he rolled into Cleveland for a
visit (which Ithink was October, but my memory does not work right now).

As time passed, I began to feel the increasing weight of my fatigue, and
grew more impatient. Time slowed down, and it seemed like we would never be
done cleaning. In truth, I think this was the fastest we have ever cleaned
up a venue, and we didn't even have our full staff of volunteers
helping. But, our minds have a funny way of warping reality, and I became
increasingly irritable (it was at this point that Dave made his remark
about my belligerent insistence that I was not being
annoying). Dave ~~suggessted~~ ordered me to go home. But, I had to wait
for the last coffee pot so that I could return them to Starbucks. This
took _forever_ (in my mind).

Finally, the last coffee pot appeared and David[^2] came with me to bring
them back to Starbucks. We agreed that I would drop him back off so he could
help finish packing up, and I would just go home, since I was more of an
annoyance than I was helpful. I got lost multiple times bringing David back.
Honestly, I probably shouldn't have been driving, but we made it back safely,
and I finally returned to my dorm. I then finished up some work I needed to do
for senior project (due tomorrow), and then began writing this post after
taking a much needed shower.

## Oh, Yeah. [I Had Goals]({{< ref hack-cwru-16.md >}})

That's right! I almost forgot (wink, wink; nudge, nudge). Setting goals seems
to be a pointless exercise unless you remember to go back and actually evaluate
how much of what you set out to do was actually accomplished. I think that it's
also important to think about _why_ you either met or failed to meet a certain
goal. Simply setting a goal for yourself does not necessarily mean that that's
what you should focus on above everything else. Unless you can predict the
future (in which case, send me an email - let's chat), some of your goals are
bound to be pretty poor, and some are bound to be flat-out wrong.

Woah. I think the lack of sleep is really starting to get to me. Without
further ado, let's take a look at how I did.


1. **Get my homework done**.
  Hey! I did this one! Well, mostly. Homework was definitely not my top
  priority during the weekend. My attention was almost fully occupied
  between keeping up with the goings-on of the hackathon, working on my
  fish scripts, and hanging out with other hackers, organizers and
  friends. However, I did manage to finish up my MATLAB homework, which I
  discussed in more detail earlier. And while I technically didn't finish
  my senior project work before I left the hackathon, it was the first
  thing I did when I got back to my dorm (which is an unusually
  responsible thing for me to do).

1. **Get back into meditation**.
  I did this one as well, though not as much as I would have liked. As
  far as I am aware, Aaron did keep up the regular meditation room
  throughout the hackathon, excepting the early morning hours, which I
  think he (wisely) spent sleeping. I attended the second session of
  HackCWRU, which took place at midnight Friday (or Saturday morning,
  depending on how picky you are about that kind of thing).\
  \
  We did a guided meditation on creativity and chakras. I have to admit
  that I was nervous at first; the meditation was twenty minutes long,
  and I hadn't meditated in over half a year. I seriously doubted my
  ability to last the entire session. But, I settled into my seat as the
  meditation began, determined to give it my best shot. I had to fight to
  stifle a few yawns in the beginning, which I'm willing to give myself a
  pass for given how late in the evening we were meditating. I then
  quickly found myself deep in the meditation. It was an amazing
  experience. I completely lost track of time, and the session had ended
  before I knew it. I didn't want to come out of the deep state of zen
  focus that I found myself in.\
  \
  We then spent a few moments discussing how we felt through the
  meditation. This was an extremely valuable experience for me, since
  when I did meditate regularly, I always did so in solitude. I never got
  to discuss what I felt and experienced with others, so the opportunity
  to share experience with others was rewarding in itself.\
  \
  I failed to attend any of the other sessions, which I think is
  unfortunate. I gained a lot of insight from those twenty minutes, and I
  wish I had taken advantage of the opportunity to explore new
  meditations with the group. At the very least, the first session helped
  me move past my nervousness about returning to meditation.

1. **Contribute to some open source**.
  In the post where I discussed my goals for HackCWRU, I defined three
  distinct areas of focus for this goal, so I will discuss each in turn
  here.\
  \
  **Get issue counts down on my repositories**.
  I made absolutely no headway here. My poor slack library still has
  as many issues as it started with. Too much time was spent on other
  activities. To be clear, though, I do not view this as a failure. I
  will always have time to work on these issues, and none of them is
  particularly pressing. The experiences I was able to have by
  putting down some of my "work" and trying new things (like being a
  DJ!) were far more valuable.\
  \
  **Fish completion for `s`**.
  Done! I got two pull requests merged in throughout the hackathon,
  with a third waiting for feedback. This ended up being a much
  bigger time-sink than I had originally anticipated. Fish can be a
  finicky beast. But, I think I was finally able to bend it to my
  will. Even though I vastly underestimated how much time this would
  take me, I think I learned a valuable lesson in making estimations
  of work. Plus, owning a feature and seeing it from conception
  through to a (finally, fingers crossed) correct implementation felt
  great. No regrets here. Maybe just a few choice words for shell
  scripting.\
  \
  **Slackbot Spotify integration**.
  Katherine never set up a shared playlist, so this never became a high
  priority goal for me. I am totally passing blame here, but, personally,
  I am glad I didn't get sucked in to this project. It likely would have
  taken _much longer_ than my work on `s`, and that
  would have taken away from the time that I got to spend in meditation
  and being the best DJ at HackCWRU. Also, in talking to Dave and a few
  other people, I amassed some other great ideas for functionality to add
  to the bot, which are arguably more useful (though not necessarily as
  fun) than adding songs to a playlist.

1. **Food Cart**!
  I actually forgot to write about this! My memory is basically
  gone. Aaron and I never got to relive the glory days of the food
  cart. The only time I was actually at the hackathon late, I was either
  DJ-ing or too hyped-up on energy drinks to focus. I completely dropped
  the ball on this one, and I'll have to make sure to make up for it next
  time around. Sorry, everyone.

## Final Thoughts

Well, this was a lot more words than I had originally intended to write. I
sat down to write a quick reflective post to bookend my HackCWRU
experience, but soon the ideas just kept coming. When things like that
happen, I tend to take this as an indication that whatever I'm writing
about had a more significant impact on me than I had originally
thought. This is actually one of the reasons why I enjoy writing so much,
and why I plan to do much more writing going forward. Writing allows me to
look inward and do some really critical introspection and figure out what
is truly important and meaningful to me.

For HackCWRU specifically, my last hackathon as a Case student provided a
tremendous amount of insight, perspective and experience. We grew the event
in size tremendously from last year, and dealing with the challenges that
accompanied this growth forced us to grow as organizers and as leaders.

Personally, I made strides both in my technical development, learning more
intricacies (sometimes begrudgingly) of the fish shell, and in my personal
development. Frankly, I am more interested in the latter - I can always
pick up another book on programming. The personal interactions and
relationships are far more interesting, rewarding and valuable. Not only
did I get to make strides to return to a meditation practice, I also got to
interact with hackers of so many different backgrounds, personalities and
communication styles and quirks (and sponsors and mentors, too). This
challenges me to grow as a person, developing more empathy (like when a
poor hacker suffered from a miscommunication on our end and was stuck in
the [cold](http://static.giantbomb.com/uploads/original/0/340/704216-tauntaun.jpg)
for twenty minutes, and communication skills (when mentoring people of
widely varying skill sets and learning styles).

I am sad that this is the last HackCWRU that I will help run as a student,
and I truly hope that I will be able to come back to help out as an
alumni. But, that is a matter for another time, far in the future. For now,
I must scan this for any glaring grammatical errors, then publish and,
finally, rest.

[^1]: Yes - hours and hours for only eighty-three lines of working code! Computers defy me sometimes. Programming is hard.
[^2]: This David is a different one. It's not Dave. Keep up, will you?
