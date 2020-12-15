#!/bin/bash
install_ansible(){
    pacman -Sy python python-pip ansible --noconfirm
    ansible-galaxy collection install community.general
}

main(){
    install_ansible
}

main

