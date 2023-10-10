#!/bin/bash

rbenv global 3.0.0
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
ruby -v 
bundle exec jekyll serve -w