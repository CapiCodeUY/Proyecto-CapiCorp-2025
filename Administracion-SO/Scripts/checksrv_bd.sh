#!/bin/bash
# Descripción: Verifica el estado del servicio MySQL/MariaDB de la Cooperativa.

# --- CONFIGURACIÓN DE VARIABLES ---
SERVICE_NAME="mariadb"                      
LOG_FILE="/var/log/checksrv_bd.log"
ADMIN_EMAIL="dba_admin@cooperativa.com"     
MAX_RETRIES=2                               

# --- FUNCIONES DE UTILIDAD ---

log_message() {
    local TYPE="$1"
    local MESSAGE="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$TYPE] $MESSAGE" | tee -a $LOG_FILE
}

send_alert() {
    local SUBJECT="$1"
    local BODY="$2"
    log_message "ALERT" "Generando alerta crítica: $SUBJECT"
    # echo "$BODY" | mail -s "$SUBJECT" "$ADMIN_EMAIL" 
    echo "Simulando envío de alerta por correo. Asunto: $SUBJECT" >> $LOG_FILE
}

# Función principal de chequeo y recuperación
check_service() {
    log_message "INFO" "Verificando estado del servicio '$SERVICE_NAME' con systemctl..."

    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_message "SUCCESS" "Servicio '$SERVICE_NAME' está activo y corriendo."
        return 0 
    else
        log_message "CRITICAL" "Servicio '$SERVICE_NAME' está INACTIVO. Iniciando ciclo de recuperación..."
        
        for i in $(seq 1 $MAX_RETRIES); do
            log_message "WARNING" "Intento $i de $MAX_RETRIES: Reiniciando servicio..."
            systemctl restart "$SERVICE_NAME" &> /dev/null
            sleep 5 
            
            if systemctl is-active --quiet "$SERVICE_NAME"; then
                log_message "SUCCESS" "Servicio '$SERVICE_NAME' reiniciado con éxito en el intento $i."
                send_alert "ALERTA: Servicio BD Reiniciado" "El servicio $SERVICE_NAME estaba inactivo y fue reiniciado automáticamente. Estado OK."
                return 0 
            fi
        done

        log_message "FATAL" "El servicio '$SERVICE_NAME' falló al iniciar después de $MAX_RETRIES intentos."
        send_alert "FALLO CRÍTICO: Servicio BD Abajo" "El servicio $SERVICE_NAME está INACTIVO y no pudo ser recuperado. Se requiere intervención manual."
        return 1 
    fi
}

# --- EJECUCIÓN DEL SCRIPT ---
log_message "INFO" "--- INICIO DE CHEQUEO DE SERVICIO DE BASE DE DATOS ---"

if check_service; then
    log_message "INFO" "Chequeo finalizado con estado OK."
    exit 0
else
    log_message "FATAL" "Chequeo finalizado con FALLA CRÍTICA."
    exit 1
fi
