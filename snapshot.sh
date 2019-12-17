#!/bin/bash

bin="/bin"
usrBin="/usr/bin"
sbin="/sbin"
usrSbin="/usr/sbin"

declare -A map

functionFind()
{
	for file in $(find $sbin)
	do
		if [[ ! -d $file ]]; then
			map[$(md5sum $file)]="$(stat --printf="%a" $file)"
			echo "$map[$(md5sum $file)]" "${map[$(md5sum $file)]}"
		else
			map[$file]="$(stat --printf="%a" $file)"
			echo "$map[$file]" "${map[$file]}"
		fi
			
	
	done > $(date +"%F_%H:%M")
     

}


die() {
    echo $1 >&2
    exit 1
}



functionFind


