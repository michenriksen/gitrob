#!/bin/sh
cat /tmp/targets.txt | xargs ./gitrob -bind-address 0.0.0.0 -in-mem-clone -mode 2
