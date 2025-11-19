#!/bin/bash

# --- CONFIGURACIÓN DE VARIABLES ---
APP_DIR="/opt/cooperativa/viviendas/app" 
BACKUP_DIR="/var/backups/app"            
DATE=$(date +%Y%m%d%H%M%S)               
BACKUP_FILE="app_viviendas_backup_${DATE}.tar.gz" 
LOG_FILE="/var/log/backup_app.log"       
MIN_SIZE_KB=1000                         

# --- FUNCIONES ---

# Función para registrar mensajes
log_message() {
    local TYPE="$1"
    local MESSAGE="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$TYPE] $MESSAGE" | tee -a $LOG_FILE
}

# Función para verificar dependencias
check_deps() {
    log_message "INFO" "Verificando comandos requeridos (tar)..."
    if ! command -v tar &> /dev/null; then
        log_message "ERROR" "El comando 'tar' no está instalado. Abortando."
        exit 1
    fi
}

# Función para verificar permisos y directorios
pre_check() {
    log_message "INFO" "Comprobando permisos y directorios..."

    # 1. Verificar directorio de origen
    if [ ! -d "$APP_DIR" ]; then
        log_message "FATAL" "Directorio de la aplicación no encontrado: $APP_DIR. Abortando."
        exit 1
    fi

    
    if [ ! -d "$BACKUP_DIR" ]; then
        log_message "WARNING" "Directorio de destino no encontrado. Creando: $BACKUP_DIR"
        mkdir -p "$BACKUP_DIR"
        if [ $? -ne 0 ]; then
            log_message "FATAL" "No se pudo crear el directorio de backup: $BACKUP_DIR. Abortando."
            exit 1
        fi
    fi
}

# Función principal de backup
perform_backup() {
    log_message "INFO" "Iniciando proceso de backup..."
    
    
    log_message "INFO" "Comprimiendo $APP_DIR en ${BACKUP_DIR}/${BACKUP_FILE}..."
    tar -czpf "${BACKUP_DIR}/${BACKUP_FILE}" "$APP_DIR" 2>> $LOG_FILE

    if [ $? -eq 0 ]; then
        log_message "SUCCESS" "Backup creado exitosamente: ${BACKUP_FILE}"
        
      
        local SIZE_KB=$(du -k "${BACKUP_DIR}/${BACKUP_FILE}" | awk '{print $1}')
        if [ "$SIZE_KB" -lt "$MIN_SIZE_KB" ]; then
            log_message "WARNING" "El archivo de backup es pequeño (${SIZE_KB} KB). Podría estar incompleto."
        else
            log_message "INFO" "Tamaño del archivo de backup verificado: ${SIZE_KB} KB."
        fi
    else
        log_message "ERROR" "Fallo la creación del backup. Consulte $LOG_FILE para detalles."
        exit 1
    fi
}

# --- EJECUCIÓN DEL SCRIPT ---
log_message "INFO" "--- INICIO DE BACKUP DE APLICACIÓN ---"
check_deps
pre_check
perform_backup
log_message "INFO" "--- FIN DE BACKUP DE APLICACIÓN ---"

exit 0
