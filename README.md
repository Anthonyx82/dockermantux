# 🧰 dockermantux

Automatiza tareas mensuales de mantenimiento en un servidor Debian 12 que utiliza Docker (gestionado por Portainer), incluyendo limpieza de sistema, verificación de discos, documentación del entorno y backup RAID0. Todo gestionado de forma segura con variables externas desde un archivo `.env`.

---

## 🚀 Características

- 🖴 Verificación SMART de discos con informe resumido
- 🔄 Reimplementación automática de stacks en Portainer vía API
- 🧹 Limpieza avanzada de Docker (contenedores, imágenes, volúmenes, redes)
- 🧽 Limpieza del sistema Debian (paquetes huérfanos, caché, logs, `/tmp`)
- 📝 Generación de documentación del entorno Docker
- 💾 Backup completo de RAID0 hacia disco externo montado
- ⏰ Configuración fácil de tarea cron mensual

---

## 📦 Requisitos

- Debian 12
- `smartmontools`
- `jq`
- `curl`
- `rsync`
- Python 3 con entorno virtual para documentación
- Docker y Portainer instalados
- Acceso root o `sudo`

Instala los requisitos básicos con:

```bash
sudo apt update
sudo apt install smartmontools jq curl rsync deborphan -y
````

---

## ⚙️ Configuración

1. **Clona el repositorio**

```bash
git clone https://github.com/Anthonyx82/dockermantux.git
cd dockermantux
```

2. **Edita el archivo `.env`**

Configura tus rutas, credenciales de Portainer y hora de ejecución:

```ini
PORTAINER_URL="http://localhost:9000/api"
PORTAINER_USERNAME="server"
PORTAINER_PASSWORD="server1313*"
PORTAINER_ENDPOINT_ID=1
...
CRON_SCHEDULE="0 2 1 * *"  # Cada 1er día del mes a las 2:00 AM
```

---

## 🛠️ Instalación

Ejecuta el script de setup para registrar la tarea cron automáticamente:

```bash
bash setup_mantenimiento.sh
```

Esto añadirá una entrada a tu crontab como esta:

```cron
0 2 1 * * bash /ruta/completa/mantenimiento_mensual.sh >> /var/log/mantenimiento_mensual.log 2>&1
```

---

## 📄 Archivos

| Archivo                    | Descripción                                    |
| -------------------------- | ---------------------------------------------- |
| `.env`                     | Configuración de entorno (editas este archivo) |
| `mantenimiento_mensual.sh` | Script principal de mantenimiento              |
| `setup_mantenimiento.sh`   | Script para registrar el cron automáticamente  |

---

## 🧪 Test manual

Puedes ejecutar el mantenimiento manualmente para probar que todo funciona:

```bash
bash mantenimiento_mensual.sh
```

---

## 📬 Autor

Desarrollado y mantenido por Anthonyx82
🔗 Contacto: [antoniomartinmanzanares2004@gmail.com](mailto:antoniomartinmanzanares2004@gmail.com)

---

## 📄 Licencia

MIT License. Libre para usar y modificar.
