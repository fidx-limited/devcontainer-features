#!/bin/env bash

source dev-container-features-test-lib

# Actual tests
check "k3d" k3d --version

# Report result
reportResults
