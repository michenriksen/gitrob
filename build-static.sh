#!/bin/bash

#Script to generate code for ./core/bindata.go

#install dependencies using the directions here:  https://github.com/elazarl/go-bindata-assetfs
go-bindata-assetfs -o ./core/bindata.go -pkg "core" ./static/*
go build
