#!/bin/bash

die() {
    echo $1 >&2
    exit 1
}

#Control de errores
[[ $# -ne 0 ]] && die "Este script hace una ""foto"" actual del estado los directorios /bin /usr/bin /sbin /usr/bin"

declare -a files
directory=("/bin" "/usr/bin" "/sbin" "/usr/sbin")
declare -A map

functionFind()
{
	for file in $(find $1)
	do
		if [[ ! -d $file ]]
		then
			map["$(md5sum $file)"]="$(stat --printf="%a" $file)"
			echo "$map[$(md5sum $file)]" "${map[$(md5sum $file)]}"
		else
			map[$file]="$(stat --printf="%a" $file)"
			echo "$map[$file]" "${map[$file]}"
		fi
	
	done
}

dir="/var/log/snapshots"
if [[ ! -d $dir ]]
then
	mkdir /var/log/snapshots
fi

dirFinal="$dir""/""$(date +"%F_%T")"
for i in "${directory[@]}"
do
	functionFind $i
done > "$dirFinal"

echo "FIN" >> "$dirFinal"
