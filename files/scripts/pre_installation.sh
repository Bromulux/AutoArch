#!/bin/bash
enlarge_live_root_partition(){
    mount -o remount,size=5G /run/archiso/cowspace
}

install_ansible(){
    pacman -Sy python python-pip ansible --noconfirm
    ansible-galaxy collection install community.general
    pip install jmespath #install -r requirements.txt
}

main(){
    enlarge_live_root_partition
    install_ansible
}

main
