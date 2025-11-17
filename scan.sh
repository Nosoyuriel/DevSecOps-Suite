#!/bin/bash

# --- Script de Interfaz para la Suite de Análisis DevSecOps ---

# Actualizamos el uso para aceptar un tercer argumento opcional para SAST
if [[ "$1" = "sast" && "$#" -ne 3 ]] || [[ "$1" != "sast" && "$#" -ne 2 ]]; then
    echo "Uso:"
    echo "  $0 sast <ruta_al_proyecto> <project_key_en_sonarqube>"
    echo "  $0 sca <ruta_al_proyecto>"
    echo "  $0 dast <URL_de_la_aplicacion>"
    echo "Ejemplo SAST: $0 sast ./my-app my-app-key"
    exit 1
fi

SCAN_TYPE=$1
TARGET=$2

# --- Lógica principal ---
case $SCAN_TYPE in
    sast)
        # --- LÓGICA PARA SAST ---
        PROJECT_KEY=$3 # El tercer argumento es la clave del proyecto
        ABS_PROJECT_PATH=$(readlink -f "$TARGET")

        if [ ! -d "$ABS_PROJECT_PATH" ]; then
            echo "Error: El directorio del proyecto '$ABS_PROJECT_PATH' no existe."
            exit 1
        fi
        
        if [ -z "$SONAR_TOKEN" ]; then
            echo "Error: La variable de entorno SONAR_TOKEN no está configurada."
            exit 1
        fi
        
        echo "--- Ejecutando Análisis Estático (SAST) para el proyecto '$PROJECT_KEY'... ---"
        
        docker run --rm \
          --network=devsecops-suite_devsecops-net \
          -v "$ABS_PROJECT_PATH:/scan" \
          devsecops-suite sonar-scanner \
          -Dsonar.projectKey="$PROJECT_KEY" \
          -Dsonar.sources=. \
          -Dsonar.host.url=http://sonarqube-server:9000 \
          -Dsonar.token="$SONAR_TOKEN"
        ;;
    
    sca|dast)
        # Mantenemos la lógica anterior para SCA y DAST sin cambios
        if [ "$SCAN_TYPE" = "sca" ]; then
            ABS_PROJECT_PATH=$(readlink -f "$TARGET")
            if [ ! -d "$ABS_PROJECT_PATH" ]; then
                echo "Error: El directorio del proyecto '$ABS_PROJECT_PATH' no existe."
                exit 1
            fi
            echo "--- Ejecutando Análisis de Dependencias (SCA) con Trivy... ---"
            docker run --rm \
              -v "$ABS_PROJECT_PATH:/scan" \
              -v ~/.cache/trivy:/root/.cache/ \
              devsecops-suite trivy fs --severity HIGH,CRITICAL --exit-code 1 /scan
        else
            echo "--- Ejecutando Análisis Dinámico (DAST) con OWASP ZAP... ---"
            REPORTS_DIR="$(pwd)/reports"
            mkdir -p "$REPORTS_DIR"
            echo "Los informes se guardarán en: $REPORTS_DIR"
            docker run --rm -w /zap/wrk \
              --network=devsecops-suite_devsecops-net \
              -v "$REPORTS_DIR:/zap/wrk" \
              devsecops-suite zap-baseline.py \
              -t "$TARGET" \
              -r zap_report.html
        fi
        ;;
        
    *)
        echo "Error: Tipo de scan '$SCAN_TYPE' no reconocido."
        exit 1
        ;;
esac
