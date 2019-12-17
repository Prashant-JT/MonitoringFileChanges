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

while read ID CHECK NAME PERM
do
	if [[ $ID == ">" || $ID == "<" ]]
	then
		if [[ $PERM != "" ]]
		then
			NAME=$(echo $NAME | tr -d ']')
			CHECK=$(echo $CHECK | tr -d '[')
			if [[ $ID == ">" && $(grep -name $NAME $snapshotOld) == "" ]]
			then
				echo "El fichero $NAME se ha añadido"
			else
				temp=$(grep -name $NAME $snapshotNow)
				if [[ $temp == "" ]]
				then
					echo "El fichero $NAME se ha eliminado"
				else
					echo "ESTO ES TEMP:"$temp"yo"
					CHECK2=$(cut -d" " -f1 $temp | tr -d '[')
					if [[ $CHECK == $CHECK2 ]]
					then
						echo "Se ha modificado los permisos del fichero $NAME"
					else
						echo "Se ha modificado el contenido del fichero $NAME"
					fi
				fi
			fi
		else
			PERM=$NAME
			NAME=$(echo $CHECK | tr -d '[]')
			CHECK=0
			
		fi
	fi
done < /var/log/dif

rm -f $snapshotNow