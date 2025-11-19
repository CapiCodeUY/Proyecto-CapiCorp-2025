#!/bin/bash

# --- CONFIGURACIÓN DE VARIABLES ---
DB_USER="backup_user"                        
DB_HOST="localhost"                          
BACKUP_DIR="/var/backups/mysql"              
DATE=$(date +%Y%m%d%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/bd_vivienda_dump_${DATE}.sql.gz" 
LOG_FILE="/var/log/backup_bd.log"
MIN_SIZE_KB=50                               

# --- FUNCIONES ---

log_message() {
    local TYPE="$1"
    local MESSAGE="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$TYPE] $MESSAGE" | tee -a $LOG_FILE
}

check_mysql_is_up() {
    log_message "INFO" "Verificando si MySQL está en ejecución con el archivo de credenciales..."
    # mysqladmin lee automáticamente las credenciales de ~/.my.cnf
    if ! mysqladmin ping &> /dev/null; then
        log_message "FATAL" "No se pudo conectar a MySQL. Revise el servicio, el archivo ~/.my.cnf o sus permisos (chmod 600)."
        exit 1
    fi
}

pre_check() {
    log_message "INFO" "Preparando entorno para el backup..."
    if [ ! -d "$BACKUP_DIR" ]; then
        log_message "WARNING" "Directorio de destino no existe. Creando: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
    fi
    if ! command -v mysqldump &> /dev/null; then
        log_message "FATAL" "Comando 'mysqldump' no encontrado."
        exit 1
    fi
}

perform_dump() {
    log_message "INFO" "Iniciando mysqldump de todas las bases de datos..."
    
    mysqldump \
        --all-databases \
        --single-transaction \
        --flush-logs \
        2> /tmp/mysqldump_error.log | gzip > "$BACKUP_FILE"
    
    DUMP_STATUS=$?
    
    if [ "$DUMP_STATUS" -eq 0 ]; then
        log_message "SUCCESS" "Dump de BD creado y comprimido exitosamente: $(basename $BACKUP_FILE)"
        verify_backup
    else
        log_message "ERROR" "Fallo el mysqldump (código de salida: $DUMP_STATUS)."
        if [ -s /tmp/mysqldump_error.log ]; then
            log_message "ERROR" "Errores de mysqldump:"
            tail -n 10 /tmp/mysqldump_error.log | while read LINE; do log_message "ERROR_DETAIL" "$LINE"; done
        fi
        rm -f "$BACKUP_FILE" 
        exit 1
    fi
    rm -f /tmp/mysqldump_error.log 
}

verify_backup() {
    log_message "INFO" "Verificando tamaño del archivo de backup..."
    if [ ! -f "$BACKUP_FILE" ]; then
        log_message "FATAL" "El archivo de backup no existe después del dump. Falla grave."
        exit 1
    fi
    
    local SIZE_KB=$(du -k "$BACKUP_FILE" | awk '{print $1}')
    if [ "$SIZE_KB" -lt "$MIN_SIZE_KB" ]; then
        log_message "WARNING" "El backup es muy pequeño (${SIZE_KB} KB). Puede ser un fallo en el dump."
    else
        log_message "SUCCESS" "Verificación de tamaño OK: ${SIZE_KB} KB."
    fi
}

# --- EJECUCIÓN DEL SCRIPT ---
log_message "INFO" "--- INICIO DE BACKUP DE BASE DE DATOS ---"
pre_check
check_mysql_is_up
perform_dump
log_message "INFO" "--- FIN DE BACKUP DE BASE DE DATOS ---"

exit 0
