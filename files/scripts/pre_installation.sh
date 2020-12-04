#!/bin/bash
enlarge_live_root_partition(){
    mount -o remount,size=5G /run/archiso/cowspace
}

install_required_packages(){
    pacman -Syu git ansible --noconfirm
}

clone_auto_arch_repo(){

}
