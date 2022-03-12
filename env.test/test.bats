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

@test "can run our script" {
  run check.sh
	assert_failure
  assert_output --partial 'Welcome to our project!'
}

#####################
# Runtime Environment
#####################

@test "working directory" {
  run pwd
	assert_success
  assert_output '/home/runner/work/actions/actions'
}

@test "ensure user" {
  run whoami
  assert_success
  assert_output 'runner'
}

@test "ensure uid" {
  run id -u
  assert_success
  assert_output '1001'
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

@test "github api url env" {
  run echo "$GITHUB_API_URL"
  assert_success
  refute_output ''
}

@test "ensure github actions runner running" {
  run pgrep Runner.Listener
  assert_success
}

########
# System
########

# https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#supported-runners-and-hardware-resources

@test "ensure more than 30gb available in workdir" {
  result=$(df --output=avail -k "$PWD"  | tail -n1)
  [[ $result -gt 30000000 ]]
}

@test "ensure more than 3gb available in /dev/shm" {
  result=$(df --output=avail -k "/dev/shm"  | tail -n1)
  [[ $result -gt 3000000 ]]
}

# 14 GB of SSD disk space (some swap space is also required)
@test "ensure more than 8gb available in /mnt" {
  result=$(df --output=avail -k "/mnt"  | tail -n1)
  [[ $result -gt 8000000 ]]
}

@test "ensure we're on the right OS image" {
  run jq .[0].detail /imagegeneration/imagedata.json
  assert_success
  assert_output '"Ubuntu\n20.04.4\nLTS"'
}

# 7 GB of RAM memory
@test "ensure more than 6gb total memory" {
  result=$(cat /proc/meminfo  | grep MemTotal | awk '{print $2}')
  [[ $result -gt 6000000 ]]
}

# 2-core CPU
@test "ensure 2 cpus" {
  result=$(lscpu -e | wc -l)
  [[ $result -eq 3 ]]
}

@test "ensure no running containers" {
  run docker info -f '{{.Containers}}'
  assert_success
  assert_output '0'
}

@test "outbound internet" {
  run curl -s -o /dev/null -w "%{http_code}" https://www.google.com
  assert_success
  assert_output '200'
}

##############
# Filesystems
##############

# https://docs.github.com/en/actions/using-github-hosted-runners/about-github-hosted-runners#file-systems

@test "home" {
  run echo "$HOME"
  assert_success
  assert_output '/home/runner'
}

@test "workspace" {
  run echo "$GITHUB_WORKSPACE"
  assert_success
  assert_output '/home/runner/work/actions/actions'
}

@test 'event path' {
  run jq -r . "$GITHUB_EVENT_PATH"
  assert_success
  refute_output ''
}

###########
# Packages
###########

@test "ensure pre-fetched docker images" {
  run docker inspect node:16
  assert_success
}

@test "ensure docker run" {
  run docker run -t --rm alpine cat /etc/alpine-release
  assert_success
  assert_output --partial '3'
}

@test "bash" {
  run bash --version
  assert_success
  assert_line --index 0 --partial 'GNU bash, version 5'
}

@test "clang" {
  run clang-12 --version
  assert_success
  assert_line --index 0 --partial 'clang version 12'
}

@test "msbuild" {
  run msbuild -version -noLogo
  assert_success
  assert_output --partial '16.'
}

@test "node" {
  run node -v
  assert_success
  assert_output --partial 'v16'
}

@test "python" {
  run python --version
  assert_success
  assert_output --partial 'Python 3'
}

@test "ruby" {
  run ruby --version
  assert_success
  assert_output --partial 'ruby 2'
}

@test "go" {
  run go version
  assert_success
  assert_output --partial 'go version'
}

@test "git" {
  run git --version
  assert_success
  assert_output --partial 'git version 2.'
}

@test "aws" {
  run aws --version
  assert_success
  assert_output --partial 'aws-cli/2'
}

###########
# Services
###########

@test "postgres" {
  sudo systemctl start postgresql.service
  run psql -V
  assert_success
  assert_output --partial 'psql (PostgreSQL)'
}

@test "mysql" {
  sudo systemctl start mysql.service
  run psql -V
  assert_success
  assert_output --partial 'psql (PostgreSQL)'
}