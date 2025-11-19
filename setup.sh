#!/bin/bash

# ==============================================================================
#  SCRIPT DE INSTALACIÓN Y CONFIGURACIÓN PARA LA SUITE DEVSECOPS
# ==============================================================================
#
#  Este script realiza las siguientes acciones:
#  1. Detiene y elimina cualquier instancia anterior de la suite para un inicio limpio.
#  2. Construye la imagen Docker 'devsecops-suite' con todas las herramientas CLI.
#  3. Inicia los contenedores de SonarQube y PostgreSQL en segundo plano.
#  4. Espera hasta que el servidor de SonarQube esté completamente operativo.
#  5. Aprovisiona SonarQube a través de su API REST:
#     - Cambia la contraseña de administrador por defecto.
#     - Crea un nuevo proyecto para los análisis.
#     - Genera un token de autenticación para ser usado por los scanners.
#
#  Requisitos: docker, docker compose, curl, jq (instalar con: sudo apt install jq)
#
# ==============================================================================

# Detener el script inmediatamente si cualquier comando falla
set -e

# --- PASO 1: LIMPIEZA DEL ENTORNO ANTERIOR ---
echo "--- [1/5] Limpiando cualquier ejecución anterior (contenedores y volúmenes)... ---"
# El flag '--volumes' asegura un reinicio totalmente limpio de la base de datos.
docker compose down --volumes --remove-orphans

# --- PASO 2: CONSTRUCCIÓN DE LA IMAGEN DE HERRAMIENTAS ---
echo "--- [2/5] Construyendo la imagen de herramientas 'devsecops-suite'... ---"
docker build -t devsecops-suite .

# --- PASO 3: INICIO DE LOS SERVICIOS DE FONDO ---
echo "--- [3/5] Iniciando servicios de SonarQube y PostgreSQL en segundo plano... ---"
docker compose up -d

# --- PASO 4: ESPERA ACTIVA DEL SERVIDOR ---
echo "--- [4/5] Esperando a que el servidor SonarQube esté completamente operativo... ---"
# Este bucle robusto espera hasta que la API de SonarQube confirme que está saludable.
until curl --output /dev/null --silent --head --fail -u admin:admin http://localhost:9000/api/system/health; do
    printf '.'
    sleep 5
done
echo -e "\n¡SonarQube está listo!"

# --- PASO 5: APROVISIONAMIENTO AUTOMÁTICO VÍA API ---
echo "--- [5/5] Aprovisionando SonarQube automáticamente... ---"

# 5a. Cambiar la contraseña de admin por defecto para asegurar la instancia.
echo "Cambiando la contraseña de 'admin' por defecto..."
curl -s -u admin:admin -X POST "http://localhost:9000/api/users/change_password?login=admin&previousPassword=admin&password=sonar_admin_password" > /dev/null

# 5b. Crear el proyecto.
PROJECT_KEY="Analisis-1"
PROJECT_NAME="Project 1"
echo "Creando el proyecto '$PROJECT_NAME' con la clave '$PROJECT_KEY'..."
curl -s -u admin:sonar_admin_password -X POST "http://localhost:9000/api/projects/create?name=$PROJECT_NAME&project=$PROJECT_KEY" > /dev/null

# 5c. Generar un nuevo token para el proyecto.
echo "Generando token de análisis..."
# Usamos 'jq' para parsear la respuesta JSON y extraer solo el token.
TOKEN=$(curl -s -u admin:sonar_admin_password -X POST "http://localhost:9000/api/user_tokens/generate?name=devsecops-suite-token" | jq -r '.token')

# --- RESUMEN FINAL ---
echo ""
echo "========================================================================"
echo "  ¡CONFIGURACIÓN AUTOMÁTICA COMPLETA!"
echo "========================================================================"
echo "  Proyecto Creado: $PROJECT_KEY"
echo "  Contraseña de admin cambiada a: sonar_admin_password"
echo ""
echo "  TU TOKEN DE ANÁLISIS ES (GUÁRDALO DE FORMA SEGURA):"
echo "  $TOKEN"
echo "========================================================================"
echo "  Para usar el token, expórtalo en tu terminal:"
echo "  export SONAR_TOKEN=\"$TOKEN\""
echo "========================================================================"
echo ""
