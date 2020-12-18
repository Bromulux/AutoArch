AutoArch is a way to automatically install Archlinux on a localhost.
I was tired to reinstalling Archlinux and worried to lose my config, so AutoArch was born.

The process was done using Ansible.
It was a way for me to learn about general automation.

This work was inspired by the https://github.com/sugarraysam/archsugar, I strongly suggest you to go see his work before mine!

I tried to follow the Archlinux official installation guide for the most part of this project (https://wiki.archlinux.org/index.php/Installation_guide). 

AutoArch is mainly build in 3 parts:

1 -  Bootstrap: This section aims to create partitions, filesystem and mount the partitions.

2 - Chroot: This section aims to make a clean bootable system.

3 - Provisioning: This is where all the magic happens; dotfiles import and UI.

In order to use AutoArch:

1 - execute the pre_installation.sh script located in files/scripts to install ansible and pip.

2 - edit/fill the vars files accordingly
    packages_vars.yml
    parition_vars.yml
    passwords.yml (encrypt the file using ansible vault) ansible-vault encrypt vars/passwords.yml
    user_vars.yml

3 - Execute bootstrap.yml
ansible-playbook -i inventory bootstrap.yml

4 - Execute chroot.yml
ansible-playbook -i inventory --ask-vault-pass chroot.yml

5 - Execute provisioning.yml
ansible-playbook -i inventory --ask-vault-pass provisioning.yml

Roadmap:
Take advantage of ansible roles.
make a python wrapper around ansible to it is easier to use.
clean up

Notes:
You will find some artefacts in files/scripts about an attempt to automate the installtion with a bash script. This was done before the work done with Ansible and was unsuccessful.