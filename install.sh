#!/usr/bin/env bash

mkdir -p ~/.bash-tools && cp -R conf/. ~/.bash-tools
sed -i -e "s@^BASH_TOOLS_FOLDER=.*@BASH_TOOLS_FOLDER=$(pwd)@g"  ~/.bash-tools/.env

if ! which parallel 2>/dev/null; then
  sudo apt update
  sudo apt install -y parallel
  # remove parallel nagware
  mkdir -p ~/.parallel
  touch ~/.parallel/will-cite
fi