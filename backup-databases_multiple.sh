#!/bin/bash

# Archivo de credenciales (por defecto)
CRED_FILE="db-credentials.txt"

# Comprobar si se pasó un argumento para el archivo de credenciales
if [[ $# -gt 0 && "$1" != --* ]]; then
    CRED_FILE="$1"
    shift  # Mover a la siguiente opción
fi

# Inicializar variables por defecto
HOST="localhost"
PORT=3306
DATABASE=""
BACKUP_PATH="/home"
COMPRESS=false  # Inicializar la flag de compresión
SSL_MODE=DISABLED  # SSL desactivado por defecto

# Procesar argumentos
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --compress) COMPRESS=true ;;  # Activa la compresión si se pasa el flag
        --host) HOST="$2"; shift ;;    # Establecer el host y mover el puntero
        --port) PORT="$2"; shift ;;     # Establecer el puerto y mover el puntero
        --database) DATABASE="$2"; shift ;;  # Establecer la base de datos y mover el puntero
        --path) BACKUP_PATH="$2"; shift ;; # Establecer la ruta donde se guardarán los respaldos
        --ssl) SSL_MODE=REQUIRED ;;  # Habilitar SSL si se pasa el flag
        *) echo "Opción desconocida: $1"; exit 1 ;;
    esac
    shift
done

# Directorio base donde se guardarán los backups
BACKUP_DIR="$BACKUP_PATH"
FECHA=$(date +"%Y-%m-%d_%H-%M-%S")

# Crear el directorio de respaldo si no existe
mkdir -p ${BACKUP_DIR}

# Leer credenciales del archivo
while IFS=: read -r USER PASSWORD; do
    echo "Usando credenciales de usuario: $USER en el host: $HOST en el puerto: $PORT con SSL_MODE=$SSL_MODE"

    if [[ -z "$DATABASE" ]]; then
        # Obtener la lista de bases de datos (excluir las del sistema)
        databases=$(mysql --host=${HOST} --port=${PORT} --user=${USER} --password=${PASSWORD} --ssl-mode=${SSL_MODE} -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema|mysql|sys)")
    else
        databases="$DATABASE"
    fi

    # Iterar sobre cada base de datos y hacer dump
    for db in $databases; do
        # Crear carpeta para cada base de datos
        DB_BACKUP_DIR="${BACKUP_DIR}/${USER}_${db}_${FECHA}"
        mkdir -p ${DB_BACKUP_DIR}

        echo "Respaldo de la base de datos: $db para el usuario: $USER"

        # Hacer el dump de la base de datos
        mysqldump --host=${HOST} --port=${PORT} --user=${USER} --password=${PASSWORD} --ssl-mode=${SSL_MODE} --databases $db > ${DB_BACKUP_DIR}/dump_${db}.sql

        # Comprimir si el flag está activado
        if [ "$COMPRESS" = true ]; then
            gzip ${DB_BACKUP_DIR}/dump_${db}.sql
            echo "Archivo comprimido: ${DB_BACKUP_DIR}/dump_${db}.sql.gz"
        else
            echo "Respaldo sin comprimir guardado en: ${DB_BACKUP_DIR}/dump_${db}.sql"
        fi
    done

    echo "Backup completado para el usuario: $USER"

done < "$CRED_FILE"

# Mensaje de finalización
echo "Todos los backups han sido completados."
