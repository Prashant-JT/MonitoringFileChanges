#!/bin/bash

callCompareSnapshot()
{
	cd /root/Escritorio
	./compare_snapshot.sh
}

callSnapshot()
{
	cd /root/Escritorio
	./snapshot.sh
}

writeChanges()
{
	cd /root/Escritorio
	touch testChanges
	echo "test1" >> testChanges
	echo "Se ha añadido un fichero nuevo en /bin/A" >> testChanges
	echo "Se ha añadido un fichero nuevo en /sbin/B" >> testChanges
	echo "Se ha añadido un directorio nuevo en /usr/bin/C" >> testChanges
	echo "Se ha añadido un directorio nuevo en /usr/sbin/D" >> testChanges

	echo "test2" >> testChanges
	echo "Se ha modificado los permisos de /bin/A => 664 -> 666" >> testChanges
	echo "Se ha modificado los permisos de /usr/bin/C => 755 -> 777" >> testChanges

	echo "test3" >> testChanges
	echo "Se ha modificado el contenido de /bin/A" >> testChanges
	echo "Se ha añadido en /usr/bin/C dos ficheros llamados C1 y C2, además de un directorio 		llamado C3" >> testChanges
	
	echo "test4" >> testChanges
	echo "Se ha eliminado el fichero /bin/A" >> testChanges
	echo "Se ha eliminado el fichero /sbin/B" >> testChanges
	echo "Se ha eliminado el directorio /usr/bin/C y su contenido" >> testChanges
}

# Ficheros y directorios nuevos añadidos en /bin /sbin /usr/bin /usr/sbin
# A => fichero
# B => fichero
# C => carpeta
# D => carpeta
test1()
{	
	touch /bin/A
	touch /sbin/B
	mkdir /usr/bin/C
	mkdir /usr/sbin/D
	
	callCompareSnapshot
	
	echo "test1 DONE"
}

# Ficheros y directorios modificados (permisos)
# A => 664 -> 666
# B => No ha cambiado
# C => 755 -> 777
# D => No ha cambiado
test2()
{
	cd /bin
	chmod 666 A

	# No debe detectar cambios de permiso (rw--r--r es por defecto al crear un fichero)
	cd /sbin
	chmod 644 B

	cd /usr/bin
	chmod 777 C

	# No debe detectar cambios de permiso (rwxr-xr-x es por defecto al crear un directorio)
	cd /usr/sbin
	chmod 755 D

	callCompareSnapshot

	echo "test2 DONE"
}

# Ficheros modificados (contenido)
# A => Ha cambiado
# B => No ha cambiado
# C => Ha cambiado y se han añadido 2 nuevos ficheros (C1 y C2) y un directorio (C3)
# D => No ha cambiado
test3()
{
	cd /bin
	echo "Este es el primer fichero" >> A

	cd /sbin
	echo "" >> B

	cd /usr/bin/C
	touch C1
	touch C2
	mkdir C3

	cd /usr/sbin/D

	callCompareSnapshot
	
	echo "test3 DONE"
}

# Ficheros y directorios eliminados
# A => Se elimina
# B => Se elimina
# C => Se elimina con sus ficheros y directorio (C1 C2 C3)
# D => No se elimina
test4()
{
	rm -f /bin/A

	rm -f /sbin/B

	rm -f -r /usr/bin/C

	# No debe detectar que se ha eliminado el directorio D

	callCompareSnapshot

	echo "test4 DONE"
	
	rmdir /usr/sbin/D
}

echo "Ejecutando batería de pruebas..."
callSnapshot
test1
callSnapshot
test2
callSnapshot
test3
callSnapshot
test4
writeChanges
rm -r -f /var/log/binchecker
