#!/bin/env bash

set -e

YQ_VERSION="${YQVERSION}"

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

architecture="$(uname -m)"
case $architecture in
    x86_64) architecture="amd64";;
    # aarch64 | armv8*) architecture="arm64";;
    # aarch32 | armv7* | armvhf*) architecture="armhf";;
    *) echo "(!) Architecture $architecture unsupported"; exit 1 ;;
esac

if [ ${YQ_VERSION} != "none" ]; then
    # Install the yq, verify checksum
    echo "Downloading yq..."
    if [ "${YQ_VERSION::1}" != 'v' ] && [ "${YQ_VERSION}" != 'latest' ]; then
        YQ_VERSION="v${YQ_VERSION}"
    fi
    curl -fsSL "https://github.com/mikefarah/yq/releases/${YQ_VERSION}/download/yq_linux_${architecture}" -o /usr/local/bin/yq

    chmod 0755 /usr/local/bin/yq
    if ! type yq > /dev/null 2>&1; then
        echo '(!) yq installation failed!'
        exit 1
    fi

    # yq bash completion
    yq shell-completion bash > "$(pkg-config --variable=completionsdir bash-completion)/yq"

    # yq zsh completion
    if [ -e "${USERHOME}}/.oh-my-zsh" ]; then
        mkdir -p "${USERHOME}/.oh-my-zsh/completions"
        yq shell-completion zsh > "${USERHOME}/.oh-my-zsh/completions/_yq"
        chown -R "${USERNAME}" "${USERHOME}/.oh-my-zsh"
    fi
fi

echo -e "\nDone!"
