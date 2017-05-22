#!/bin/sh

if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  bundle exec fastlane test
  exit $?
fi
