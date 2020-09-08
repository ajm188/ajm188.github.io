---
title: "Switch Local Binding"
date: 2020-07-03T20:22:37-04:00
draft: true
---

```go
n := f() // assume f returns int

if n > 0 {
    handlePositive()
} else if n < 0 {
    handleNegative()
} else {
    handleZero()
}
```

words

```go
n := f()
switch n {
case 0:
    handleZero()
default:
    // ??? sigh ...
}
```

words

```go
switch n := f(); {
case > 0:
    handlePositive()
case < 0:
    handleNegative()
default:
    handleZero()

```

words

```go
if err := someFunc(); err != nil { // binds err and then conditions on it
}

switch n := f(); true {
case n > 0: // matches when (n > 0) == true
    handlePositive()
}
```
