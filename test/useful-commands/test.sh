#!/bin/env bash

source dev-container-features-test-lib

# Actual tests
check "yq" yq --version

# Report result
reportResults
