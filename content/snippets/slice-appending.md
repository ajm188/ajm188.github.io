---
title: "Slice Appending"
date: 2020-07-03T16:44:08-04:00
draft: true
summary: Concise dynamic slice appending.
---

Presented with the following requirements:
* The list should always contain the same first element.
* The passed string should always be the last element of the list.
* Any additional strings should appear between the static first element and the given last element.

The first go at this might look something like this:

```go
func foo(last string, args []string) []string {
    var list []string
    switch n := len(args); {
    case n > 0:
        list = append([]string{"first"}, args...)
        list = append(list, last)
    default:
        list = []string{"first", last}
    }

    return list
}
```

This is pretty verbose for the simple task we're trying to accomplish, and it would be great if we could
write this in a cleaner, more concise way. Taking advantage of couple details[^1], we can do this one of two ways:

```go
func foo(last string, args []string) []string {
    return append([]string{"first"}, append(args, last)...)
}
```

```go
func foo(last string, args []string) []string {
    return append(append([]string{"first"}, args...), last)
}
```

I prefer the second version arbitrarily.

[^1]: Those details:
      * calling a function with an empty slice as the variadic arg is the same as not passing those args at all (i.e. `append(x, y...)` is the same as `append(x)` when `y` is an empty slice)
      * appending "nothing" to a slice returns the original slice
