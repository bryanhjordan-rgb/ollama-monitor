#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
go test -race ./...
swift test --package-path macos
