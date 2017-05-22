#!/bin/sh

if [[ "$TRAVIS_PULL_REQUEST" != "false" ]]; then
  fastlane test
  exit $?
fi
