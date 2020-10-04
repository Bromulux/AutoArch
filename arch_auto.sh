#!/bin/bash

#functions:
print_error() {
    #https://stackoverflow.com/questions/2990414/echo-that-outputs-to-stderr
    echo "[Error] $1"
}

check_boot_mode() {
    if [ -d "/sys/firmware/efi/efivars" ]; then
        echo "Boot Mode [OK]"
        return 0
    else
        print_error "Boot mode is not UEFI."
        exit 1
    fi
}

check_internet_connection() {
    if ping "archlinux.org" -c 3 >/dev/null; then
        echo "Internet Connection [OK]"
    else
        print_error "Not connected to the internet"
        exit 1
    fi
}

connect_wifi() {
    #todo
    return 1
}

update_system_clock() {
    timedatectl set-ntp true
    if timedatectl status | awk '/System clock synchronized: yes/ && /NTP service: active/'; then
        echo "System clock update [OK]"
    else
        print_error "System clock not updated"
    fi
}

pre-installation_Checks() {
    check_boot_mode
    check_internet_connection
    return 0
}

partition_disk(){
    return 1
}

general_checks
update_system_clock
