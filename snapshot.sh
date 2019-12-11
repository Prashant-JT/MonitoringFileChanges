#!/bin/bash

bin="/bin"
usrBin="/usr/bin"
sbin="/sbin"
usrSbin="/usr/sbin"

declare -A map

functionFind()
{
	for file in $(find $bin)
	do
		if [[ ! -d $file ]]
		then
			map[$(md5sum $file)]="$(stat --printf="%a" $file)"
		else
			map[$file]="$(stat --printf="%a" $file)"
		fi
		echo "$map[$(md5sum $file)]" "${map[$(md5sum $file)]}"	

	done
}

die() {
    echo $1 >&2
    exit 1
}



functionFind

