#!/bin/bash

# === Cargar configuración desde .env ===
ENV_PATH="$(dirname "$0")/.env"
if [ ! -f "$ENV_PATH" ]; then
  echo "Archivo .env no encontrado en $ENV_PATH. Abortando."
  exit 1
fi

set -o allexport
source "$ENV_PATH"
set +o allexport

{
  echo "===== INFORME RESUMIDO DE ESTADO DE SALUD DE DISCOS ====="
  echo "Fecha: $(date)"
  echo "Hostname: $(hostname)"
  echo "=========================================================="
  echo

  DISCOS=($(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print $1}'))

  for disco in "${DISCOS[@]}"; do
    DEVICE="/dev/$disco"
    echo "🖴 Disco: $DEVICE"

    MODELO=$(sudo smartctl -i "$DEVICE" | grep -E "Device Model|Product" | awk -F: '{print $2}' | sed 's/^[ \t]*//')
    MODELO_FAMILIA=$(sudo smartctl -i "$DEVICE" | grep -E "Model Family" | awk -F: '{print $2}' | sed 's/^[ \t]*//')
    echo "Modelo: ${MODELO_FAMILIA:-$MODELO}"

    ESTADO=$(sudo smartctl -H "$DEVICE" | grep "SMART overall-health" | awk -F: '{print $2}' | xargs)
    echo "Estado SMART: $ESTADO"

    HORAS_ON=$(sudo smartctl -A "$DEVICE" | awk '$1 == "9" {print $10}')
    echo "Horas encendido: ${HORAS_ON:-Desconocido}"

    REALLOC=$(sudo smartctl -A "$DEVICE" | awk '$1 == "5" {print $10}')
    echo "Sectores reasignados: ${REALLOC:-0}"

    PENDING=$(sudo smartctl -A "$DEVICE" | awk '$1 == "197" {print $10}')
    echo "Sectores pendientes: ${PENDING:-0}"

    UNCORR=$(sudo smartctl -A "$DEVICE" | awk '$1 == "198" {print $10}')
    echo "Sectores no corregibles: ${UNCORR:-0}"

    ATA_ERRORS=$(sudo smartctl -l error "$DEVICE" | grep -i "Error:" | wc -l)
    echo "Errores ATA registrados: $ATA_ERRORS"

    if [[ "$ESTADO" == "PASSED" ]] && [[ "$REALLOC" -eq 0 ]] && [[ "$PENDING" -eq 0 ]] && [[ "$UNCORR" -eq 0 ]] && [[ "$ATA_ERRORS" -eq 0 ]]; then
      echo "🔹 Estado: BUENO"
    elif [[ "$REALLOC" -gt 100 || "$PENDING" -gt 0 || "$UNCORR" -gt 0 || "$ATA_ERRORS" -gt 10 ]]; then
      echo "❌ Estado: CRÍTICO – Se recomienda reemplazo"
    else
      echo "⚠️ Estado: CON OBSERVACIONES – Revisar periódicamente"
    fi

    echo "----------------------------------------------------------"
    echo
  done

  echo "===== FIN DEL INFORME ====="
} | sudo tee "$LOGFILE" > /dev/null

echo "===== Iniciando Mantenimiento Mensual $(date) ====="

# REINICIO STACKS PORTAINER
PORTAINER_TOKEN=$(curl -s -X POST "$PORTAINER_URL/auth" \
  -H "Content-Type: application/json" \
  -d "{\"Username\":\"$PORTAINER_USERNAME\", \"Password\":\"$PORTAINER_PASSWORD\"}" \
  | jq -r .jwt)

STACKS=$(curl -s -X GET "$PORTAINER_URL/stacks" \
  -H "Authorization: Bearer $PORTAINER_TOKEN")

echo "Reiniciando stacks..."
echo "$STACKS" | jq -c '.[]' | while read -r stack; do
  ID=$(echo "$stack" | jq -r .Id)
  NAME=$(echo "$stack" | jq -r .Name)
  echo "Reimplementando stack: $NAME (ID $ID)..."
  curl -s -X PUT "$PORTAINER_URL/stacks/$ID/redeploy?endpointId=$PORTAINER_ENDPOINT_ID" \
    -H "Authorization: Bearer $PORTAINER_TOKEN" > /dev/null
done

# LIMPIEZA DE DOCKER
echo "Limpiando contenedores detenidos..."
docker container prune -f
echo "Eliminando imágenes sin uso..."
docker image prune -a -f
echo "Eliminando volúmenes huérfanos..."
docker volume prune -f
echo "Eliminando redes no utilizadas..."
docker network prune -f

# LIMPIEZA DEL SISTEMA
echo "===== Iniciando limpieza de sistema Debian ====="
sudo apt autoremove -y
sudo apt remove $(deborphan) -y
sudo apt clean
sudo apt autoclean
sudo journalctl --vacuum-time=7d
sudo rm -rf /tmp/*

# DOCUMENTACIÓN
echo "Actualizando documentación del entorno..."
cd "$DOCKER_DOCS_DIR"
source "$VENV_PATH/bin/activate"
python3 "$DOCS_SCRIPT"
deactivate

# BACKUP RAID0
echo "===== Iniciando backup mensual RAID0 ====="
if mountpoint -q "$RAID0_BACKUP"; then
    rsync -avh --delete "$RAID0_SOURCE" "$RAID0_BACKUP" >> "$RAID0_LOG" 2>&1
    echo "Backup completado: $(date)" >> "$RAID0_LOG"
else
    echo "ERROR: $RAID0_BACKUP no está montado. Backup cancelado." >> "$RAID0_LOG"
fi

# REINICIO DEL SISTEMA
echo "Reiniciando el servidor..."
sudo reboot
