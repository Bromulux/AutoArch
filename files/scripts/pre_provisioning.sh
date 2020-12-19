#!/bin/bash
install_galaxy_packages(){
    ansible-galaxy install kewlfft.aur
}

main (){
    install_galaxy_packages
}

main
