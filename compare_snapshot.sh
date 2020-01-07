#!/bin/bash

#Función que desvía los mensajes a la salida estándar de errores.
die() {
    echo $1 >&2
    exit 1
}

dir="/var/log/snapshots" #El directorio donde se almacenan los backups.
dirChanges="/var/log/binchecker" #El directorio donde se almacenará los ficheros con los cambios

#Opción por defecto, compara el estado actual con el primer backup realizado.
#Opción "-l", compara el estado actual con el último backup realizado.
[[ $# -gt 1 ]] && die "Este script puede aceptar un argumento. Uso: $0 [-l], para comparar con el último backup."

#Control de errores 1:
##Puede que no se haya ejecutado ninguna vez una copia de seguridad, por lo que el archivo snapshot no existe
if [[ ! -d "$dir" ]]
then
	die "No se ha realizado ninguna copia de seguridad anteriormente (/var/log/snapshots no encontrado)"
elif [[ ! "$(ls $dir)" ]]
then
	die "No existe ninguna copia de seguridad en /var/log/snapshots"
fi

#Control de errores 2: 
##Puede que no se haya realizado ningún fichero de cambios anteriormente y este sea la primera vez en ejecutarse
if [[ ! -d "$dirChanges" ]]
then
	mkdir $dirChanges
fi

if [[ $1 == "-l" ]]
then
	snapshotOld=$(ls -t $dir | head -1) #El último backup realizado.
elif [[ $# -eq 0 ]]
then
	snapshotOld=$(ls -t $dir | tail -1) #El primer backup realizado.
else 
	die "Argumento erróneo. Uso: $0 [-l], para comparar con el último backup."
fi

#Control de errores 3:
##Puede que se haya realizado un backup incompleto, debido a un parón del script.Por ello se pone marcas finales para reconocerlos.
if [[ $(tail -n 1 "$dir""/""$snapshotOld") != "FIN" ]]
then
	die "La copia de seguridad: ""$snapshotOld ""está incompleta"
fi

executeComparation()
{
	#Se ejcuta el script de backups para obtener una "foto" actual y compararla con la última realizada.
	bash ./snapshot.sh
	snapshotNow=$(ls -t $dir | head -1)

	#Estas variables se utilizan sólo cuando se encuentra un directorio.
	hashcodeNewF=""
	permNewF=""
	direcNewF=""
	permNewD=""
	direcNewD=""

	#Ayuda para visualizar mejor la salida.
	echo "Nuevo(*), Suprimido(**), Modificado(***)\n" > "$dirChanges""/""changes_""$snapshotNow"

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
				if [[ $(grep -E "$hashcode" $dir"/"$snapshotOld) == "" ]] #Si el nombre del directorio no está presente en el backup anterior, es nuevo.
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
					fi
					if [[ $permNewF != $perm ]]
					then 
						echo -e "\tSe cambiaron sus permisos: permisos antiguos-> "$perm" - permisos nuevos-> "$permNewF
					fi
				fi
			else #Todo aquello que sean directorios.
				if [[ $(grep -E "$hashcode" $dir"/"$snapshotNow) == "" ]] #Si el nombre del directorio no está presente en el backup nuevo, se ha suprimido.
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
	done >> "$dirChanges""/""changes_""$snapshotNow" #El registro de los cambios se desvía a la ruta actual.

	#Se procede a eliminar dicho backup auxiliar, si no se borrase adecuadamente
	#quedaría presente una marca para identificarlo y no tenerlo en cuenta.
	rm -f "$dir""/""$snapshotNow"
}

crontabOption()
{
	#Comprueba si ya existe una configuración antigua o no
	if [[ $(crontab -l | grep "compare_snapshot.sh$") == "" ]]
	then
		#Implementación del crontab
		read -n 1 -p "¿Desea que se realice un backup periódicamente? [s/n]: " OPTION
		echo ""
		if [[ $OPTION == "s" ]]
		then	
			read -p "¿En qué minuto debe realizarlo? [00-59|*]: " MIN
			regex="^([0-5]?[0-9]|\*)$"
			[[ ! $MIN =~ $regex ]] && die "Los minutos son incorrectos"

			read -p "¿A qué hora debe realizarlo? [00-23|*]: " HOUR
			regex="^([0-2]?[0-23]|\*)$"
			[[ ! $HOUR =~ $regex ]] && die "Las horas son incorrectas"

			read -p "¿En qué día del mes debe realizarlo? [01-31|*]: " DOM
			regex="^([0-2]?[1-9]|30|31|\*)$"
			[[ ! $DOM =~ $regex ]] && die "El día del mes es incorrecto"	
	
			read -p "¿En qué mes debe realizarlo? [01-12|*]: " MON
			regex="^(0?[1-9]|10|11|12|\*)$"
			[[ ! $MON =~ $regex ]] && die "El mes es incorrecto"
		
			read -p "¿En qué día de la semana debe realizarlo? [0-6|*]: " DOW
			regex="^([0-6]|\*)$"
			[[ ! $DOW =~ $regex ]] && die "El día de la semana es incorrecto"
		
			route=$(pwd)"/compare_snapshot.sh"
			echo "$MIN $HOUR $DOM $MON $DOW $route" >> mycron
			echo "Se ha guardado la configuración con éxito"		
			crontab mycron
			rm -f mycron
		fi
	fi
}

executeComparation
crontabOption
