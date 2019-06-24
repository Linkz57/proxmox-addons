#!/bin/sh
## Written by Tyler Francis on 2019-06-24_15-09-28
## Version 1.0
## The Proxmox Virtual Environment node was just told to shut down or reboot.
## We should migrate off all containers and VMs because there's always a small chance this node is never coming back
## And while it's easy enough to move text files around /etc/pve/nodes it's inconvenient,
## daunting to new/casual users, and it took me a whole year to find that folder! Not at all discoverable.



## Before doing all this work, make sure there are other online nodes available to migrate to, and that they aren't just named "rarely-online".
if /usr/bin/pvesh get /nodes --output-format text --noborder 1 --noheader 1 |
/bin/grep -v $(/bin/hostname) |
/usr/bin/cut -d' ' -f2 |
/bin/grep online > /dev/null
then



	## First shut down all Containers and VMs, because the fastest migrations happen offline.
	/usr/bin/pvesh --nooutput create /nodes/localhost/stopall



	for lxc in $(/usr/bin/pvesh get /nodes/localhost/lxc --output-format json-pretty | ## Find all LXC containers using the Proxmox API,
	/bin/grep '\"vmid\"' | ## then remove everything except the line containing "vmid" with quotes,
	/usr/bin/cut -d':' -f2 | ## remove the JSON key name whatever,
	/usr/bin/cut -d'"' -f2) ## and finally then cut out the quote marks, leaving only a list of VMID numbers
	do
		## Now that we have the list of all LXC containers, migrate them off one-at-a-time to the first node you can find that isn't you.
		/usr/bin/pvesh --nooutput create /nodes/localhost/lxc/$lxc/migrate --restart --target $(/usr/bin/pvesh get /nodes --noborder 1 --noheader 1 | ## Start a migration, and get a list of every node you could migrate your LXC containers to.
		/bin/grep -v $(/bin/hostname) | ## Remove your own name from the list, because migrating to yourself is useless.
		/bin/grep online | ## Filter the list of nodes down to just the folk online at the moment, thus able to be migrated to
		/usr/bin/cut -d' ' -f1 | ## Remove all the metadata like number of cores each node has, and what its favorite color is. An offline migration doesn't need a lot of resources, just anything with a pulse.
		/usr/bin/head -n1) ## Just choose the top of the list. A random spray re-rolled for each migration might be better for a lot of reasons, but it's also harder to clean up afterwards.
	done



	## Find all VMs using the Proxmox API, then cut out everything except the actual VMID. Same as above.
	for qemu in $(/usr/bin/pvesh get /nodes/localhost/qemu --output-format json-pretty |
	/bin/grep '\"vmid\"' |
	/usr/bin/cut -d':' -f2 |
	/usr/bin/cut -d'"' -f2)
	do
		## and again, migrate them off one-at-a-time to the first node that isn't you. Hooray for subshells.
		/usr/bin/pvesh --nooutput create /nodes/localhost/qemu/$qemu/migrate --online --target $(/usr/bin/pvesh get /nodes --noborder 1 --noheader 1 |
		/bin/grep -v $(/bin/hostname) |
		/bin/grep online |
		/usr/bin/cut -d' ' -f1 |
		/usr/bin/head -n1)
	done

fi
