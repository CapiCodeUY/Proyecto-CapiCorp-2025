#!/bin/bash


SERVICE_NAME="docker"                         
CONTAINER_NAMES="frontend_app backend_api"    
LOG_FILE="/var/log/checksrv_app.log"
ADMIN_EMAIL="admin@cooperativa.com"           
HEALTH_STATUS=0                               

# --- FUNCIONES ---

log_message() {
    local TYPE="$1"
    local MESSAGE="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$TYPE] $MESSAGE" | tee -a $LOG_FILE
}

send_alert() {
    local SUBJECT="$1"
    local BODY="$2"
    log_message "ALERT" "Enviando alerta: $SUBJECT"
    
    echo "Simulando envío de alerta por correo. Asunto: $SUBJECT" >> $LOG_FILE
}

# 1. Verificar el estado del servicio Docker
check_docker_service() {
    log_message "INFO" "Verificando estado del servicio '$SERVICE_NAME' con systemctl..."
    if systemctl is-active --quiet "$SERVICE_NAME"; then
        log_message "SUCCESS" "Servicio '$SERVICE_NAME' está activo y corriendo."
    else
        log_message "CRITICAL" "Servicio '$SERVICE_NAME' está INACTIVO. Intentando reiniciar..."
        systemctl start "$SERVICE_NAME" &> /dev/null
        if systemctl is-active --quiet "$SERVICE_NAME"; then
            log_message "SUCCESS" "Servicio '$SERVICE_NAME' se reinició con éxito."
            send_alert "Docker Service Restarted" "El servicio $SERVICE_NAME estaba inactivo y fue reiniciado automáticamente."
        else
            log_message "FATAL" "Fallo al reiniciar el servicio '$SERVICE_NAME'."
            send_alert "CRITICO: Docker Abajo" "El servicio $SERVICE_NAME está inactivo y no pudo ser reiniciado. Se requiere intervención manual."
            HEALTH_STATUS=2
            return
        fi
    fi
}

# 2. Verificar el estado de contenedores clave
check_containers() {
    for CONTAINER in $CONTAINER_NAMES; do
        log_message "INFO" "Verificando estado del contenedor '$CONTAINER'..."
        if docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q "true"; then
            log_message "SUCCESS" "Contenedor '$CONTAINER' está corriendo."
        else
            log_message "CRITICAL" "Contenedor '$CONTAINER' NO está corriendo. Intentando levantarlo..."
            docker start "$CONTAINER" &> /dev/null
            if docker inspect -f '{{.State.Running}}' "$CONTAINER" 2>/dev/null | grep -q "true"; then
                log_message "SUCCESS" "Contenedor '$CONTAINER' se levantó con éxito."
                send_alert "Contenedor Reiniciado" "El contenedor $CONTAINER estaba inactivo y fue reiniciado automáticamente."
            else
                log_message "FATAL" "Fallo al iniciar el contenedor '$CONTAINER'."
                send_alert "CRITICO: Contenedor Abajo" "El contenedor $CONTAINER está inactivo y no pudo ser iniciado. Revise Docker."
                HEALTH_STATUS=2
            fi
        fi
    done
}

# --- EJECUCIÓN DEL SCRIPT ---
log_message "INFO" "--- INICIO DE CHEQUEO DE SERVICIOS DE APLICACIÓN ---"
check_docker_service
if [ "$HEALTH_STATUS" -lt 2 ]; then 
    check_containers
fi

if [ "$HEALTH_STATUS" -eq 2 ]; then
    log_message "FATAL" "El chequeo terminó con fallas críticas."
    exit 2
else
    log_message "INFO" "Chequeo de servicios de aplicación finalizado sin fallas críticas."
    exit 0
fi
