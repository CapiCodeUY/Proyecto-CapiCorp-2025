#!/bin/bash
# Descripción: Comprueba que la BD principal de la Cooperativa de Viviendas responda consultas y tenga registros.

# --- CONFIGURACIÓN DE VARIABLES ---
DB_USER="healthcheck_user"                # Usuario definido en ~/.my.cnf
DB_NAME="bd_vivienda_coop"                # Nombre de la base de datos principal (AJUSTAR)
TABLE_NAME="socios"                       # Nombre de una tabla crítica (ej. 'viviendas', 'socios') (AJUSTAR)
LOG_FILE="/var/log/checkdb_response.log"
MIN_ROWS=1                                # Mínimo de filas esperado en la tabla crítica

# --- FUNCIONES DE UTILIDAD ---

log_message() {
    local TYPE="$1"
    local MESSAGE="$2"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [$TYPE] $MESSAGE" | tee -a $LOG_FILE
}

# Función de pre-verificación de conectividad
check_connectivity() {
    log_message "INFO" "Verificando conectividad básica de MySQL con mysqladmin (usando ~/.my.cnf)..."
    
    if mysqladmin ping &> /dev/null; then
        log_message "SUCCESS" "Conectividad básica con MySQL OK."
        return 0
    else
        log_message "FATAL" "Fallo la conexión. Revise permisos de ~/.my.cnf (600) o el servicio de BD."
        return 1
    fi
}

# Función para verificar la respuesta de consultas y datos
check_database_response() {
    log_message "INFO" "Ejecutando consulta de prueba en la base de datos $DB_NAME..."
    
    # mysql lee automáticamente las credenciales de ~/.my.cnf
    QUERY_RESULT=$(mysql -D"$DB_NAME" -N -s -e "SELECT COUNT(*) FROM $TABLE_NAME;" 2> /tmp/db_error.log)
    MYSQL_EXIT_CODE=$?

    if [ $MYSQL_EXIT_CODE -eq 0 ]; then
        log_message "SUCCESS" "Consulta de prueba exitosa. Registros en $TABLE_NAME: $QUERY_RESULT"
        
        if [ "$QUERY_RESULT" -lt "$MIN_ROWS" ]; then
            log_message "CRITICAL" "La tabla $TABLE_NAME tiene $QUERY_RESULT registros (BAJO). Posible problema de datos/aplicación."
            return 1
        else
            log_message "SUCCESS" "Conteos de registros OK."
            return 0
        fi
    else
        log_message "FATAL" "Fallo la ejecución de la consulta. Posiblemente la base de datos $DB_NAME no está disponible."
        log_message "ERROR_DETAIL" "Consulte /tmp/db_error.log para detalles de MySQL."
        return 1
    fi
    rm -f /tmp/db_error.log
}

# --- EJECUCIÓN DEL SCRIPT ---
log_message "INFO" "--- INICIO DE CHEQUEO DE RESPUESTA DE BASE DE DATOS ---"

if ! check_connectivity; then
    log_message "FATAL" "No se puede continuar, fallo la conectividad básica."
    exit 1
fi

if check_database_response; then
    log_message "INFO" "Chequeo de respuesta de BD finalizado con estado OK."
    exit 0
else
    log_message "FATAL" "Chequeo de respuesta de BD fallido."
    exit 1
fi
