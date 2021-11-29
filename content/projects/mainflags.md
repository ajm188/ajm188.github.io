---
title: "mainflags"
date: 2020-11-28T23:44:29-04:00
repo: https://github.com/ajm188/mainflags
---

A `golangci-lint` linter to catch places where you add flags on the global
flagset in non-`main` packages.

This can cause issues in library code where importing packages can add flags to
your binary, and also prevent you from defining flags with the same name.
