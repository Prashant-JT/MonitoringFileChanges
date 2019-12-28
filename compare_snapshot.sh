#!/bin/bash

dir=/var/log/binchecker
[[ ! -d $dir ]] && die "No existe ninguna copia anterior"
[[ $# -ne 0 ]] && die "No debe tener ningún argumento"

snapshotOld=$(ls $dir -t | head -1)
$(/root/Escritorio/snapshot.sh)
snapshotNew=$(ls $dir -t | head -1)

echo "El old es: $snapshotOld" 
echo "El new es: $snapshotNew"

while read CHECK NAME PERM
do
	if [[ $PERM != "" ]]
	then	
		line=$(grep "$NAME" "$dir/$snapshotOld")
		if [[ $line == "" ]]
		then
			echo "El fichero $NAME es un añadido desde la última copia"
		else
			CHECKold=$(echo $line | cut -d" " -f1)
			NAMEold=$(echo $line | cut -d" " -f2)
			PERMold=$(echo $line | cut -d" " -f3)
			if [[ $CHECKold != $CHECK ]]
			then
				echo "El fichero $NAME ha cambiado de contenido"
			elif [[ $PERMold != $PERM ]]
			then
				echo "El fichero $NAME ha cambiado de permisos"
			fi
		fi
	else
		PERM=$(echo $NAME)
		NAME=$(echo $CHECK)
		CHECK=0
		echo "$NAME es un directorio"
	fi
done < "$dir/$snapshotNew"

rm -f "$dir/$snapshotNew"
