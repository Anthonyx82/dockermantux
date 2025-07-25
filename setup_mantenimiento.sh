#!/bin/bash

# Script para configurar la tarea cron del mantenimiento mensual

ENV_FILE="$(dirname "$0")/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ Archivo .env no encontrado. Abortando."
  exit 1
fi

# Cargar variables
set -o allexport
source "$ENV_FILE"
set +o allexport

# Ruta del script de mantenimiento
SCRIPT_DIR="$(dirname "$0")"
MAINTENANCE_SCRIPT="$SCRIPT_DIR/mantenimiento_mensual.sh"

if [[ ! -f "$MAINTENANCE_SCRIPT" ]]; then
  echo "❌ Script de mantenimiento no encontrado en: $MAINTENANCE_SCRIPT"
  exit 1
fi

# Crear entrada cron
CRON_CMD="$CRON_SCHEDULE bash $MAINTENANCE_SCRIPT >> /var/log/mantenimiento_mensual.log 2>&1"

# Registrar en crontab (si no existe ya)
(crontab -l 2>/dev/null | grep -Fv "$MAINTENANCE_SCRIPT" ; echo "$CRON_CMD") | crontab -

echo "✅ Tarea cron configurada:"
echo "$CRON_CMD"
