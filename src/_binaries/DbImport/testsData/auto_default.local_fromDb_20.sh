#!/usr/bin/env bash

# cat represents the whole list of tables
cat |
  grep -v '^table1$' | # table size 29MB
  grep -v '^table2$' | # table size 10MB
#  grep -v '^table3$' | # table size 4MB
cat
