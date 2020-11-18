#! /bin/bash

printf "root\nroot\n" | passwd
systemctl start sshd.service