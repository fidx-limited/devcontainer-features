#!/bin/env bash

source dev-container-features-test-lib

# Actual tests
check "k3s" k3s -v

# Report result
reportResults
