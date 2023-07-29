#!/bin/env bash

source dev-container-features-test-lib

# Actual tests
check "kubectl" kubectl version --client
check "helm" helm version --client
check "kustomize" helm version --client
check "helmfile" helm version --client
check "tilt" tilt version
check "kubectx" kubectx -h
check "kubens" kubens -h

# Report result
reportResults
