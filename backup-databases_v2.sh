#!/bin/bash

# Información de conexión a la base de datos
HOST="localhost"
USER="your-db-user"
PASSWORD="your-db-password"

# Directorio base donde se guardarán los backups
BACKUP_DIR="/home"
FECHA=$(date +"%Y-%m-%d_%H-%M-%S")

# Flag para compresión
COMPRESS=false

# Procesar argumentos
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --compress) COMPRESS=true ;;  # Activa la compresión si se pasa el flag
        *) echo "Opción desconocida: $1"; exit 1 ;;
    esac
    shift
done

# Crear el directorio de respaldo si no existe
mkdir -p ${BACKUP_DIR}

# Obtener la lista de bases de datos (excluir las del sistema)
databases=$(mysql --user=${USER} --password=${PASSWORD} --host=${HOST} -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")

# Iterar sobre cada base de datos
for db in $databases; do
    # Crear carpeta para cada base de datos
    DB_BACKUP_DIR="${BACKUP_DIR}/${db}_${FECHA}"
    mkdir -p ${DB_BACKUP_DIR}

    echo "Respaldo de la base de datos: $db"

    # Hacer el dump de la base de datos
    mysqldump --user=${USER} --password=${PASSWORD} --host=${HOST} --databases $db > ${DB_BACKUP_DIR}/dump_${db}.sql

    # Comprimir si el flag está activado
    if [ "$COMPRESS" = true ]; then
        gzip ${DB_BACKUP_DIR}/dump_${db}.sql
        echo "Archivo comprimido: ${DB_BACKUP_DIR}/dump_${db}.sql.gz"
    else
        echo "Respaldo sin comprimir guardado en: ${DB_BACKUP_DIR}/dump_${db}.sql"
    fi
done

# Mensaje de finalización
echo "Backup completado. Todos los archivos se guardaron en ${BACKUP_DIR}"
