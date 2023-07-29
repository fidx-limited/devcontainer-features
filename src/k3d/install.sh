#!/bin/env bash

set -e

K3D_VERSION="${K3DVERSION}"

USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

USERHOME="/home/$USERNAME"
if [ "$USERNAME" = "root" ]; then
    USERHOME="/root"
fi

apt_get_update()
{
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Ensure apt is in non-interactive to avoid prompts
export DEBIAN_FRONTEND=noninteractive

# Install dependencies
check_packages curl ca-certificates coreutils gnupg2 pkg-config bash-completion
# if ! type git > /dev/null 2>&1; then
#     check_packages git
# fi

# Install the K3d, verify checksum
echo "Downloading K3d..."
if [ "${K3D_VERSION::1}" != 'v' ]; then
    K3D_VERSION="v${K3D_VERSION}"
fi
curl -fsSL https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | TAG="${K3D_VERSION}" bash

if ! type k3d > /dev/null 2>&1; then
    echo '(!) K3d installation failed!'
    exit 1
fi

# K3d bash completion
k3d completion bash > "$(pkg-config --variable=completionsdir bash-completion)/k3d"

# K3d zsh completion
if [ -e "${USERHOME}}/.oh-my-zsh" ]; then
    mkdir -p "${USERHOME}/.oh-my-zsh/completions"
    k3d completion zsh > "${USERHOME}/.oh-my-zsh/completions/_k3d"
    chown -R "${USERNAME}" "${USERHOME}/.oh-my-zsh"
fi

echo -e "\nDone!"
