#!/bin/bash

# Información de conexión a la base de datos
HOST="localhost"
USER="your-db-user"
PASSWORD="your-db-password"

# Directorio donde se guardarán los dumps
BACKUP_DIR="/home"
FECHA=$(date +"%Y-%m-%d_%H-%M-%S")

# Crear el directorio de respaldo si no existe
mkdir -p ${BACKUP_DIR}

# Dump de todas las bases de datos
mysqldump --user=${USER} --password=${PASSWORD} --host=${HOST} --all-databases > ${BACKUP_DIR}/dump_todas_bases_${FECHA}.sql

# Comprimir el archivo para ahorrar espacio
gzip ${BACKUP_DIR}/dump_todas_bases_${FECHA}.sql

# Mensaje de finalización
echo "Backup completado y guardado en ${BACKUP_DIR}/dump_todas_bases_${FECHA}.sql.gz"
