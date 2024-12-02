#!/usr/bin/env bash
GOOS=linux GOARCH=amd64 go build
scp hatefeed hatefeed.nanovad.com:
