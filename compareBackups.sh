#!/bin/bash

#Función que desvía los mensajes a la salida estándar de errores.
die() {
    echo $1 >&2
    exit 1
}
###################################################


dir="/var/log/binchecker" #El directorio donde se almacenan los backups.

#Control de errores 1: 
##Puede que se haya alterado la carpeta contenedora de los backups.
##Puede que no se haya realizado ninguna copia de seguridad anteriormente.
if [[ ! -d "$dir" ]]
then
	die "No se ha realizado ninguna copia de seguridad anteriormente (/var/log/binchecker no encontrado)"
elif [[ ! "$(ls $dir)" ]]
then
	die "No existe ninguna copia de seguridad en /var/log/binchecker"
fi
#####################################################


snapshotOld=$(ls -t $dir | head -1) #El último backup realizado.

#Control de errores 2:
##Puede que se haya realizado un backup incompleto, debido a un parón del script.
##Puede que el último backup sea un backup temporal creado por este script, esto
##sucedería si se detuvo este script. Por ello se pone marcas finales para reconocerlos.
if [[ $(tail -n 1 "$dir""/""$snapshotOld") == "PRUEBA" ]]
then
	rm -f "$dir""/""$snapshotOld"
elif [[ $(tail -n 1 "$dir""/""$snapshotOld") != "FIN" ]]
then
	die "La copia de seguridad: ""$snapshotOld ""(más reciente) está incompleta"
fi
######################################################

#Se ejcuta el script de backups para obtener una "foto" actual y compararla con la última realizada.
bash ./makeAbackup.sh
snapshotNow=$(ls -t $dir | head -1)
######################################################

#Estas variables se utilizan sólo cuando se encuentra un directorio.
hashcodeNewF=""
permNewF=""
direcNewF=""
permNewD=""
direcNewD=""

#Ayuda para visualizar mejor la salida.
echo "Nuevo(*), Suprimido(**), Modificado(***)\n" > "changes_""$snapshotNow"
######################################################

#En el backup, se guarda la información de la siguiente manera:
#Directorios-> [Ruta__Directorio] Permisos
#No directorios-> [Checksum Ruta_No_Directorio] Permisos

#El diff retorna todas las diferencias presentes en ambos ficheros, usando
#los símbolos de mayor o menor para especificar dichos cambios. 
#'<' Sólo presentes en el nuevo fichero.
#'>' Sólo presentes en el viejo fichero.
#El caso especial pasa cuando para un mismo archivo se representa dos veces, tanto
#con el símbolo mayor como el menor. Significa que el ese archivo ha sido modificado.

#Se normalizan los espacios, se eliminan los corchetes y se envía la salida del
#diff, a través de una tubería, a un bucle "while".
diff "$dir""/""$snapshotNow" "$dir""/""$snapshotOld" | tr -s ' ' | tr -d "[]" |
while IFS=' ' read sign hashcode direc perm 
do	
	if [[ $sign == '<' ]] #Cambios y archivos nuevos.
	then
		if [[ $perm != "" ]] #Todo aquello que no sean directorios.
		then
			if [[ $(grep -E " $direc]" $dir"/"$snapshotOld) == "" ]] #Si el nombre del fichero no está presente en el backup antiguo, es nuevo.
			then 
				echo "*Nuevo archivo desde la ultima copia de seguridad: "$direc
			else #Si está, es que ha habido alguna moficiación, se guarda sus datos para la siguiente iteración.
				hashCodeNewF=$hashcode
				permNewF=$perm
				direcNewF=$direc
			fi
		else #Todo aquello que sean directorios.
			if [[ $(grep -E "[$hashcode]" $dir"/"$snapshotOld) == "" ]] #Si el nombre del directorio no está presente en el backup anterior, es nuevo.
			then 
				echo "*Nueva carpeta desde la ultima copia de seguridad: "$hashcode 
			else #Si está, es que ha habido alguna modificación, se guarda sus datos, aparte, para la siguiente iteración.
				permNewD=$direc
				direcNewD=$hashcode
			fi
		fi
	elif [[ $sign == '>' ]] #Cambios y archivos borrados
	then
		if [[ $perm != "" ]] #Todo aquello que no sean directorios.
		then
			if [[ $(grep -E " $direc]" $dir"/"$snapshotNow) == "" ]] #Si el nombre del fichero no está presente en el backup nuevo, se ha suprimido.
			then 
				echo "**Archivo suprimido desde la ultima copia de seguridad: "$direc
			else #Si está, es que se ha modificado, y como es un fichero, puede cambiar tanto su checksum como sus permisos.
				echo "***Archivo modificado desde la ultima copia de seguridad: "$direcNewF
				if [[ $hashCodeNewF != $hashcode ]]
				then
					echo -e "\tSe cambio su contenido: hashcode antiguo-> "$hashcode" - hashcode nuevo-> "$hashCodeNewF
				else 
					echo -e "\tSe cambiaron sus permisos: permisos antiguos-> "$perm" - permisos nuevos-> "$permNewF
				fi
			fi
		else #Todo aquello que sean directorios.
			if [[ $(grep -E "[$hashcode]" $dir"/"$snapshotNow) == "" ]] #Si el nombre del directorio no está presente en el backup nuevo, se ha suprimido.
			then 
				echo "**Carpeta suprimida desde la ultima copia de seguridad: "$hashcode
			else #Si está, es que se ha modificado, y como es un directorio sólo pueden cambiar sus permisos.
				echo "***Carpeta modificada desde la ultima copia de seguridad: "$direcNewD
				if [[ $permNewD != $direc ]]
				then
					echo -e "\tSe cambiaron sus permisos: permisos antiguos-> "$direc" - permisos nuevos-> "$permNewD
				fi
			fi
		fi
	fi
done >> "changes_""$snapshotNow" #El registro demlos cambios se desvía a la ruta actual.


#Se escribe una muestra para identificar que es un backup auxiliar.
#Se procede a eliminar dicho backup auxiliar, si no se borrase adecuadamente
#quedaría presente una marca para identificarlo y no tenerlo en cuenta.
echo "PRUEBA" >> "$dir""/""$snapshotNow"
rm -f "$dir""/""$snapshotNow"
#############################################
