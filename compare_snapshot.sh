#!/bin/bash

dir=/var/log/carpeta
[[ ! -d $dir ]] && die "No hay nignuna copia Snapshot anterior"
[[ $# -ne 0 ]] && die "No se necesita ningún argumento"

snapshotOld=$(ls /var/log/carpeta -t | head -1)
$(/var/log/snapshot.sh)
snapshotNow=$(ls /var/log/carpeta -t | head -1)
echo "$snapshotOld"
echo "$snapshotNow"

cd /var/log/carpeta/
diff $snapshotOld $snapshotNow > /var/log/dif

while read CHECK NAME PERM
do
	# Es un fichero
	if [[ $PERM != "" ]]
	then
		#NAME=$(echo $NAME | tr -d ']')
		CHECK=$(echo $CHECK | tr -d '[')
		if [[ $(grep $NAME $snapshotOld | tr -s " ") == "" ]]
		then
			NAME=$(echo $NAME | tr -d ']')
			echo "El fichero $NAME se ha añadido"
		else
			CHECKold=$(grep $NAME $snapshotOld | tr -s " " | cut -d" " -f1 | tr -d '[')
			PERMold=$(grep $NAME $snapshotOld | tr -s " " | cut -d" " -f3)
			if [[ $CHECK != $CHECKold ]]
			then
				echo "Se ha modificado el contenido del fichero $NAME"
			elif [[ $PERM -ne $PERMold ]]
			then
				echo "Se ha modificado los permisos del fichero $NAME"
			else
				continue
			fi
		fi
	# Es un directorio
	else
		PERM=$NAME
		NAME=$(echo $CHECK | tr -d '[]')
		CHECK=0
	fi
done < /var/log/carpeta/$snapshotNow

rm -f $snapshotNow
