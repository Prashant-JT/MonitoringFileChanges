#!/bin/bash

declare -a files
directory=("/bin" "/usr/bin" "/sbin" "/usr/sbin")
declare -A map

die() {
    echo $1 >&2
    exit 1
}

functionFind()
{
	for file in $(find $1)
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

for i in "${directory[@]}"
do
	functionFind $i
done


