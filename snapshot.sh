#!/bin/bash

die() 
{
    echo $1 >&2
    exit 1
}

printHelp()
{	
	echo "Descripción: Realiza una ""foto"" actual del sistema de los" 
	echo -e "\t     directorios: /bin /usr/bin /sbin /usr/bin." 
	echo -e "\t     Crea una carpeta en /var/log/snapshots en la cual"
	echo -e "\t     guarda un fichero con su fecha y hora de creación."
	echo ""
	echo -e "usage:  ./snapshot.sh"
	echo ""
	echo -e "\t-h  Muestra la ayuda"
	die
}


#Control de errores
if [[ $1 == "-h" ]]
then
	printHelp
fi
[[ $# -ne 0 ]] && die "Este script hace una ""foto"" actual del estado los directorios /bin /usr/bin /sbin /usr/bin"

declare -a files
declare -A map
directory=("/bin" "/usr/bin" "/sbin" "/usr/sbin")
dir="/var/log/snapshots"

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

executeSnapshot()
{
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
}

executeSnapshot
