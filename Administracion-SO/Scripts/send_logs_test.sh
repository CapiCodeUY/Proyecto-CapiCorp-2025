#!/bin/bash

# --- CONFIGURACIÓN DE VARIABLES -
LOG_DIR="/var/log/aplicacion"             
REMOTE_USER="backup_user"                 
REMOTE_HOST="192.168.56.30"               
REMOTE_PATH="/backups/logs/app_viviendas" 
LOG_FILE="/var/log/send_logs_app.log"     
# Opciones de rsync seguras
RSYNC_OPTIONS="-avz -e ssh"
STATUS_SUCCESS=0
STATUS_FAILURE=1

# --- FUNCIONES DE UTILIDAD 

log_message() {
    local TYPE="$1"
    local MESSAGE="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$TYPE] $MESSAGE" | tee -a $LOG_FILE
}

# Función de pre-verificación de entorno
pre_check() {
    log_message "INFO" "Comprobando entorno y dependencias..."

    if ! command -v rsync &> /dev/null; then
        log_message "FATAL" "El comando 'rsync' no está instalado. Abortando."
        exit $STATUS_FAILURE
    fi

    if [ ! -d "$LOG_DIR" ]; then
        log_message "FATAL" "El directorio de logs local ($LOG_DIR) no existe. Abortando."
        exit $STATUS_FAILURE
    fi

    log_message "WARNING" "Verificando conexión SSH. Debe usar clave pública/privada (sin passphrase)."
}

perform_sync() {
    log_message "INFO" "Iniciando sincronización de logs a $REMOTE_HOST..."
    
    # El '/' en $LOG_DIR/ copia el contenido.
    RSYNC_COMMAND="rsync $RSYNC_OPTIONS $LOG_DIR/ $REMOTE_USER@$REMOTE_HOST:$REMOTE_PATH"

    eval "$RSYNC_COMMAND" 2>> $LOG_FILE
    RSYNC_EXIT_CODE=$?

    if [ $RSYNC_EXIT_CODE -eq 0 ]; then
        log_message "SUCCESS" "Sincronización de logs completada exitosamente."
    elif [ $RSYNC_EXIT_CODE -eq 12 ]; then
        log_message "ERROR" "Fallo de rsync: Error de conexión o autenticación. Revise las Claves SSH."
        return $STATUS_FAILURE
    else
        log_message "ERROR" "Fallo la sincronización de logs (código: $RSYNC_EXIT_CODE). Consulte el log."
        return $STATUS_FAILURE
    fi
}

# --- EJECUCIÓN DEL SCRIPT 
log_message "INFO" "--- INICIO DE ENVÍO DE LOGS DE APLICACIÓN ---"
pre_check

if perform_sync; then
    log_message "INFO" "--- ENVÍO DE LOGS FINALIZADO ---"
    exit $STATUS_SUCCESS
else
    log_message "FATAL" "--- ENVÍO DE LOGS FALLIDO. REVISAR ERRORES. ---"
    exit $STATUS_FAILURE
fi
