#!/bin/bash

gather_disk_info() {
    { lsblk -f; echo ""; fdisk -l; } >> /tmp/archauto/disk_info.log
}

gather_disk_info