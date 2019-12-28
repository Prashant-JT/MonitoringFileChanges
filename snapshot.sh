#!/bin/bash

declare -A map
declare -a files
directory=("/bin" "/sbin" "/usr/bin/" "/usr/sbin")

functionFind()
{
	for file in $(find $1)
	do
		if [[ ! -d $file ]]
		then
			map[$(md5sum $file)]="$(stat --printf="%a" $file)"
			echo "$map[$(md5sum $file)]" "${map[$(md5sum $file)]}"
		else
			map[$file]="$(stat --printf="%a" $file)"
			echo "$map[$file]" "${map[$file]}"
		fi
	done
}

dir="/var/log/binchecker/"
if [[ ! -d $dir ]]
then
	mkdir /var/log/binchecker
fi

for i in "${directory[@]}"
do
	functionFind $i
done > "$dir$(date +"%F_%H:%M:%S")"
