#!/usr/bin/env bats

setup() {
    load 'test_helper/bats-support/load'
    load 'test_helper/bats-assert/load'

    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"
    # make executables in src/ visible to PATH
    PATH="$DIR:$PATH"
}

teardown() {
    : # Cleanup steps go here
}

# Assertion usage here: https://github.com/bats-core/bats-assert#usage

#####################
# Runtime Environment
#####################

@test "working directory" {
  run pwd
  assert_success
  assert_output '/__w/actions/actions'
}

@test "ensure user" {
  run whoami
  assert_success
  assert_output 'root'
}

@test "ensure uid" {
  run id -u
  assert_success
  assert_output '0'
}

# https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#administrative-privileges-of-github-hosted-runners
# The Linux and macOS virtual machines both run using passwordless sudo
@test "ensure sudo" {
  run sudo whoami
  assert_success
  assert_output 'root'
}

@test "env" {
  run echo "$CI"
  assert_success
  assert_output 'true'
}

#############################
# Docker Container Filesystem
#############################

# https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#docker-container-filesystem

# GitHub reserves the /github path prefix and creates three directories for actions.

@test "github actions filesystem" {
  run ls /github
  assert_success
  assert_line --index 0 'home' # /github/home
  assert_line --index 1 'workflow' # /github/workflow
}

