#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

read -p "Do you want to copy SSH keys? (y/N) " response
if [[ "$response" =~ ^[yY](es)?$ ]]; then
    echo "Copying SSH keys from /media/sf_.ssh/ to $HOME/.ssh/"
    mkdir -p $HOME/.ssh
    sudo bash -c "cp /media/sf_.ssh/id_rsa* $HOME/.ssh/"
    sudo bash -c "cp /media/sf_.ssh/known_hosts* $HOME/.ssh/"
    sudo chown -R $USER:$USER $HOME/.ssh/
    sudo chmod 700 $HOME/.ssh
    sudo chmod 600 $HOME/.ssh/id_rsa $HOME/.ssh/known_hosts $HOME/.ssh/known_hosts.old
    sudo chmod 644 $HOME/.ssh/id_rsa.pub
    echo "SSH keys copied and permissions set."
else
    echo "Skipping SSH keys copy."
fi