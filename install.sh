#!/usr/bin/env bash

mkdir -p ~/.bash-tools && cp -R conf/. ~/.bash-tools
sed -i -e "s@^BASH_TOOLS_FOLDER=.*@BASH_TOOLS_FOLDER=$(pwd)@g"  ~/.bash-tools/.env

sudo apt update
sudo apt install -y parallel
# remove parallel nagware
mkdir ~/.parallel
touch ~/.parallel/will-cite
