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
    exit 1
}

update_system_clock() {
    timedatectl set-ntp true
    if timedatectl status | awk '/System clock synchronized: yes/ && /NTP service: active/'; then
        echo "System clock update [OK]"
    else
        print_error "System clock not updated"
    fi
}

pre-installation_checks() {
    check_boot_mode
    check_internet_connection
}

partition_disk(){
    #https://superuser.com/questions/332252/how-to-create-and-format-a-partition-using-a-bash-script
    #(echo n; echo p; echo 1; echo 1; echo 200; echo w) | fdisk /dev/sdc
    exit 1
}

pre-installation_checks
update_system_clock
