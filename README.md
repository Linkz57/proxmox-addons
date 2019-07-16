# Proxmox Addons
### Extra bits I want to be used in and around proxmox. Maybe this affects KVM, LXC, Debian, or guest VMs.

custom_migrate_vo.service is a SystemD service that shuts down then migrates VMs and Containers to first OTHER node it sees, with the help of its buddy: custom_migrate_vo.sh

proxmox-rolling-update.sh is a single script run on a single node.
I think I'll either re-write it in Ansible, or just have Ansible copy the script to a given node, then run the script, then go onto the next box, one at a time.
