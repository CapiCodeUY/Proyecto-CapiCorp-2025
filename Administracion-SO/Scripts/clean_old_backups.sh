#!/bin/bash
# Descripción: Limpia archivos de backup antiguos según la política de retención para liberar espacio.

# --- CONFIGURACIÓN DE VARIABLES ---
BACKUP_ROOT_DIR="/var/backups"                # Directorio raíz donde están todos los backups (BD y APP)
RETENTION_DAYS=7                              
LOG_FILE="/var/log/clean_backups.log"
MIN_FREE_SPACE_PERCENT=10                     

# --- FUNCIONES ---

log_message() {
    local TYPE="$1"
    local MESSAGE="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$TYPE] $MESSAGE" | tee -a $LOG_FILE
}

check_disk_space() {
    log_message "INFO" "Verificando espacio libre en disco para $BACKUP_ROOT_DIR..."
    local USED_PERCENT=$(df -P "$BACKUP_ROOT_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    local FREE_PERCENT=$((100 - USED_PERCENT))
    
    log_message "INFO" "Espacio libre actual: ${FREE_PERCENT}%"

    if [ "$FREE_PERCENT" -lt "$MIN_FREE_SPACE_PERCENT" ]; then
        log_message "WARNING" "Espacio libre bajo (${FREE_PERCENT}%). Se ejecutará la limpieza."
    else
        log_message "SUCCESS" "Espacio libre adecuado."
    fi
}

# Retención avanzada: Elimina archivos más antiguos que RETENTION_DAYS
perform_cleanup() {
    log_message "INFO" "Buscando archivos de backup más antiguos que ${RETENTION_DAYS} días en ${BACKUP_ROOT_DIR}..."
    
    # Encontrar archivos antiguos y guardar la lista en un archivo temporal
    find "$BACKUP_ROOT_DIR" -type f -mtime +"$RETENTION_DAYS" -name "*backup*" -print0 > /tmp/files_to_delete.txt
    
    if [ ! -s /tmp/files_to_delete.txt ]; then
        log_message "INFO" "No se encontraron archivos de backup para eliminar."
        rm -f /tmp/files_to_delete.txt
        return
    fi
    
    log_message "WARNING" "Iniciando eliminación de $(wc -l < /tmp/files_to_delete.txt) archivos antiguos."

    # Eliminar archivos y loguear
    while IFS= read -r -d $'\0' FILE; do
        if [ -f "$FILE" ]; then
            log_message "DELETE" "Eliminando: $FILE"
            rm -f "$FILE"
            if [ $? -ne 0 ]; then
                log_message "ERROR" "Fallo al eliminar el archivo $FILE."
            fi
        fi
    done < /tmp/files_to_delete.txt

    rm -f /tmp/files_to_delete.txt
    log_message "SUCCESS" "Proceso de limpieza finalizado."
}

# --- EJECUCIÓN DEL SCRIPT ---
log_message "INFO" "--- INICIO DE LIMPIEZA DE BACKUPS ANTIGUOS ---"
check_disk_space
perform_cleanup
log_message "INFO" "--- FIN DE LIMPIEZA DE BACKUPS ANTIGUOS ---"

exit 0
