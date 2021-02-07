#!/bin/bash

export CYAN='\033[1;36m'
export GREEN='\033[1;32m'
export RED='\033[1;31m'
export NC='\033[0m' # No Color
function log_cyan() { echo -e "${CYAN}$@${NC}"; }
function log_green() { echo -e "${GREEN}$@${NC}"; }
function log_red() { echo -e "${RED}$@${NC}"; }

BASE=${HOME}/project/env
mkdir -p ${BASE}

# Clone dotfiles repo
# Origin will be updated after github credentials are received.
if [[ ! -d ${BASE}/dotfiles ]]; then
    log_cyan "INFO: Cloning dotfiles repo to ${BASE}/dotfiles..."
    (
        cd ${BASE}
        git clone https://github.com/danisla/dotfiles.git
    )
else
    log_green "INFO: Dotfiles repo already cloned"
fi

# Prompt for github credentials
CONFIGURE_GITHUB_CREDS=true

if [[ -f ${HOME}/.github_credentials ]]; then
    source ${HOME}/.github_credentials
    if [[ -n "${GITHUB_USERNAME}" && -n "${GITHUB_TOKEN}" ]]; then
        CONFIGURE_GITHUB_CREDS=false
    fi
fi

if [[ ${CONFIGURE_GITHUB_CREDS} == true ]]; then
    read -p "Enter Github username: " GITHUB_USERNAME
    read -s -p "Enter Github accesss token: " GITHUB_TOKEN
    printf "\n"

    cat - > ${HOME}/.github_credentials <<EOF
export GITHUB_USERNAME=${GITHUB_USERNAME}
export GITHUB_TOKEN=${GITHUB_TOKEN}
EOF
    chmod 0600 ${HOME}/.github_credentials

    log_cyan "INFO: Configured github clone credentials for user: ${GITHUB_USERNAME}"
else
    log_green "INFO: ~/.github_credentials file already configured"
fi

# Source githubrc file to get helper functions used to clone remaining repos
# This implicitly sources the ~/.github_credentials file.
source ${BASE}/dotfiles/githubrc

# Create symlink to gitconfig
if [[ ! -e ${HOME}/.gitconfig ]]; then
    log_cyan "INFO: Creating symlink to ${BASE}/dotfiles/gitconfig -> ${HOME}/.gitconfig"
    (
        cd $HOME
        ln -sf ${BASE/$HOME\/}/dotfiles/gitconfig .gitconfig
    )
else
    log_green "INFO: gitconfig already configured"
fi

# Update dotfiles remote origin with access token URL
DEST_DOTFILES_ORIGIN="https://${GITHUB_USERNAME}:${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/dotfiles.git"
CURR_DOTFILES_ORIGIN=$(cd ${BASE}/dotfiles && git remote get-url origin)
if [[ "${CURR_DOTFILES_ORIGIN}" != "${DEST_DOTFILES_ORIGIN}" ]]; then
    log_cyan "INFO: Updating dotfiles repo origin with access token"
    (
        cd ${BASE}/dotfiles
        git remote set-url origin ${DEST_DOTFILES_ORIGIN}
    )
else
    log_green "INFO: dotfiles remote origin already configured"
fi

# Clone dockerfiles repo
if [[ ! -d ${BASE}/dockerfiles ]]; then
    log_cyan "INFO: Cloning dockerfiles repo to ${BASE}/dockerfiles..."
    (
        cd ${BASE}
        git-clone-my dockerfiles
    )
else
    log_green "INFO: dockerfiles repo already cloned"
fi

# Clone gcloudfunc repo
if [[ ! -d ${BASE}/gcloudfunc ]]; then
    log_cyan "INFO: Cloning gcloudfunc repo to ${BASE}/gcloudfunc..."
    (
        cd ${BASE}
        git-clone-my gcloudfunc
    )
else
    log_green "INFO: gcloudfunc repo already cloned"
fi

# Clone kubefunc repo
if [[ ! -d ${BASE}/kubefunc ]]; then
    log_cyan "INFO: Cloning kubefunc repo to ${BASE}/kubefunc..."
    (
        cd ${BASE}
        git-clone-my kubefunc
    )
else
    log_green "INFO: kubefunc repo already cloned"
fi

# Source kubefun to get helper functions
source ${BASE}/kubefunc/kubefunc.bash

# Install k9s
if [[ ! -e ${HOME}/bin/k9s ]]; then
    log_cyan "INFO: Installing k9s"
    download-latest-k9s
else
    log_green "INFO: k9s is already installed, delete ${HOME}/bin/k8s and run download-latest-k9s to update"
fi

# Install istioctl
if [[ ! -e ${HOME}/bin/istioctl ]]; then
    log_cyan "INFO: Installing istioctl"
    download-latest-istioctl
else
    log_green "INFO: istioctl is already installed, delete ${HOME}/bin/istioctl and run download-latest-istio to update"
fi

# Install opa
if [[ ! -e ${HOME}/bin/opa ]]; then
    log_cyan "INFO: Installing opa"
    download-latest-opa
else
    log_green "INFO: opa is already installed, delete ${HOME}/bin/k8s and run download-latest-opa to update"
fi

# Clone kube-ps1 repo
if [[ ! -d ${BASE}/kube-ps1 ]]; then
    log_cyan "INFO: Cloning kube-ps1 repo to ${BASE}/kube-ps1"
    git clone https://github.com/jonmosco/kube-ps1.git ${BASE}/kube-ps1
else
    log_green "INFO: kube-ps1 repo already cloned"
fi

if ! grep -q 'source ${HOME}/project/env/dotfiles/danrc' ${HOME}/.bashrc; then
    log_cyan "INFO: Updating bashrc"
    echo 'source ${HOME}/project/env/dotfiles/danrc' | tee -a ${HOME}/.bashrc
else
    log_green "INFO: bashrc already updated"
fi

# Create symlink to tmux.conf
if [[ ! -e ${HOME}/.tmux.conf ]]; then
    log_cyan "INFO: Creating symlink to ${BASE}/dotfiles/tmux.conf -> ${HOME}/.tmux.conf"
    (
        cd $HOME
        ln -sf ${BASE/$HOME\/}/dotfiles/tmux.conf .tmux.conf
    )
else
    log_green "INFO: tmux.conf already configured"
fi

log_green "INFO: Done, restart shell to see changes"