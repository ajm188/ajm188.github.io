---
title: "go-jsonpb"
date: 2020-09-25T19:49:17-04:00
repo: https://github.com/ajm188/go-jsonpb
---

A small `protoc` compiler plugin that adds custom `json.Marshaler`
implementations to your protobuf message types to use
[`jsonpb.Marshaler`][jpb_marshaler] under the hood.

[jpb_marshaler]: https://pkg.go.dev/github.com/golang/protobuf/jsonpb#Marshaler

The primary motivation for doing this is to have enums marshaled to their string
values, rather than integers, which is the behavior of the standard
`encoding/json` marshaler.
