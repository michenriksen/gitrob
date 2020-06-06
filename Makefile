#
# Copyright (c) 2015, Matt Jones <urlugal@gmail.com>
# All rights reserved.
# MIT License
# For full license text, see the LICENSE file in the repo root or https://opensource.org/licenses/MIT
#
# version 0.1.24
#
 SHELL = /bin/bash

.PHONY: all build clean coverage help install package pretty test

# The name of the binary to build
#
ifndef pkg
pkg := $(shell pwd | awk -F/ '{print $$NF}')
endif

# Set the target OS
# Ex: windows, darwin, linux
#
ifndef target_os
	UNAME_S := $(shell uname -s)
	
	ifeq ($(UNAME_S),Linux)
		target_os = linux
	endif
	ifeq ($(UNAME_S),Darwin)
		target_os = darwin
	endif
	
	UNAME_P := $(shell uname -p)

	ifeq ($(UNAME_P),x86_64)
		target_arch = amd64
	endif
endif

ifeq ($(target_os),windows)
	target_ext = .exe
endif

ifndef target_arch
	target_arch = amd64
endif


all: pretty clean build

build: prep
	@GOOS=$(target_os) GOARCH=$(target_arch) go build -o ./bin/$(pkg)-$(target_os)

release: prep
	@GOOS=$(target_os) GOARCH=$(target_arch) go build -ldflags="-s -w" -o ./bin/$(pkg)$(target_ext)

clean:
	@rm -rf ./bin ./rules

# TODO: write help command for Makefile
# TODO: documentation
help:

install: pretty
	@GOOS=$(target_os) GOARCH=$(target_arch) go install

package: test clean build

prep:
	@go get -u

pretty:
	@golint ./...
	@go fmt ./...
	@go vet ./...

test: pretty
	@cd ./...$(pkg) && go test -cover

