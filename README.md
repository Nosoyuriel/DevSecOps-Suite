
# Guía de Uso de la Suite DevSecOps

Este documento proporciona las instrucciones necesarias para configurar y ejecutar la suite de análisis de seguridad.

## 1. Requisitos Previos

Antes de comenzar, asegúrate de cumplir con los siguientes requisitos:

1.  **Configuración del Kernel para Docker:**
    Si el contenedor de SonarQube no se ejecuta correctamente, es posible que necesites ajustar la memoria virtual del kernel.

    *   **Comando Temporal** (se ejecuta cada vez que reinicias el equipo):
        ```bash
        sudo sysctl -w vm.max_map_count=262144
        ```

    *   **Comando Permanente** (se ejecuta una sola vez):
        ```bash
        echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
        ```

2.  **Instalar `jq`:**
    Las herramientas generan respuestas en formato JSON, por lo que `jq` es necesario.
    ```bash
    sudo apt-get update && sudo apt-get install -y jq
    ```


## 2. Instalación

1.  **Permisos de Ejecución:**
    Otorga permisos de ejecución a todos los scripts del proyecto.
    ```bash
    git clone https://github.com/Nosoyuriel/DevSecOps-Suite.git
    cd DevSecOps-Suite
    ```
2.  **Permisos de Ejecución:**
    Otorga permisos de ejecución a todos los scripts del proyecto.
    ```bash
    chmod +x *.sh
    ```
3.  **Ejecutar el script de configuración inicial:**
    
    ***NOTA 1**: Utiliza este comando solo si es la primera vez que se ejecutará la suite.*

    ***NOTA 2**: Puedes ver más de la configuracion inicial en el aparartedo "3. Configuración Inicial de Análisis Estático.*
    ```bash
    ./setup.sh
    ```

## 3. Configuración Inicial de Análisis Estático

Este proceso es para la primera vez que se ejecuta la suite.

1.  **Modificar el script `setup.sh`:**
    *   **Nombre y clave del proyecto:** Edita las siguientes líneas para establecer el nombre y la clave de tu proyecto.Por defecto vendrá con la llave del proyecto "project=DevSecOps1” y el Nombre “name=DevSecOps”.
        ```bash
        curl -s -u admin:sonar_admin_password -X POST "http://localhost:9000/api/projects/create?name=DevSecOps%20Project%201&project=DevSecOps1"
        ```
    *   **Contraseña de administrador:** Cambia la contraseña `sonar_admin_password` en la siguiente línea.
        ```bash
        curl -s -u admin:admin -X POST "http://localhost:9000/api/users/change_password?login=admin&previousPassword=admin&password=sonar_admin_password"
        ```
2.  **Guardar el token:** Después de la configuración, asegúrate de guardar el token que se genere para usarlo más adelante.
    ```bash
    export SONAR_TOKEN="<tu_token_aqui>"
    ```

## 4. Ejecución de los 3 Análisis (Primera Vez)

Sigue estos pasos para realizar un análisis completo por primera vez.

1.  **Ejecutar el script de configuración inicial:**
    *NOTA: Utiliza este comando solo si es la primera vez que se ejecutará la suite.*
    ```bash
    ./setup.sh
    ```

2.  **Exportar el token de SonarQube:**
    Reemplaza `"tu_token_aqui"` con el token generado para tu proyecto.
    ```bash
    export SONAR_TOKEN="tu_token_aqui"
    ```
    Para verificar que el token se ha exportado correctamente, ejecuta:
    ```bash
    echo $SONAR_TOKEN
    ```

3.  **Ejecutar todos los análisis:**
    Proporciona la ruta del proyecto que deseas analizar.
    ```bash
    ./analyze.sh <ruta_del_proyecto_a_analizar>
    ```
    *Ejemplo:*
    ```bash
    ./analyze.sh ~/Documentos/Pruebas/juice-shop
    ```

## 5. Visualización de Resultados

1.  **Análisis de Dependencias (SCA):**
    Los resultados se mostrarán directamente en la terminal al finalizar el escaneo.

2.  **Análisis Estático (SAST):**
    *   Abre tu navegador y ve a `http://localhost:9000`.
    *   Inicia sesión con las credenciales `admin:sonar_admin_password` (o la nueva contraseña que hayas establecido).
    *   Navega al proyecto que configuraste para ver el dashboard de resultados. También puedes acceder directamente desde: `http://localhost:9000/dashboard?id=DevSecOps1`.

3.  **Análisis Dinámico (DAST):**
    Se generará un reporte en formato HTML en la carpeta `~/reports` dentro del directorio de la suite.

## 6. Ejecución de Análisis Individuales

Puedes ejecutar cada tipo de análisis por separado.

### Análisis Estático (SAST)

1.  **Exportar el token del proyecto:**
    ```bash
    export SONAR_TOKEN="tu_token_aqui"
    ```
2.  **Ejecutar el script de escaneo:**
    El script requiere 3 argumentos: el tipo de análisis (`sast`), la ruta del proyecto y la clave del proyecto.

    *   **Desde el directorio de la suite:**
        ```bash
        ./scan.sh sast ~/directorio/a/escanear clave_del_proyecto
        ```
        *Ejemplo:*
        ```bash
        ./scan.sh sast ~/Documentos/Pruebas/juice-shop juice-shop
        ```
    *   **Desde el directorio del proyecto a analizar:**
        ```bash
        ~/DevSecOps-Suite/scan.sh sast .
        ```

### Análisis Dinámico (DAST)

1.  **Ejecutar el script de escaneo:**
    El script requiere 2 argumentos: el tipo de análisis (`dast`) y la URL de la aplicación web.
    ```bash
    ./scan.sh dast http://url_de_la_app_web
    ```
    *Ejemplo:*
    ```bash
    ./scan.sh dast http://juice-shop-dast:3000
    ```

### Análisis de Dependencias (SCA)

1.  **Ejecutar el script de escaneo:**
    El script requiere 2 argumentos: el tipo de análisis (`sca`) y la ruta del proyecto.
    *   **Desde el directorio de la suite:**
        ```bash
        ./scan.sh sca ~/directorio/a/escanear
        ```
    *   **Desde el directorio del proyecto a analizar:**
        ```bash
        ~/DevSecOps-Suite/scan.sh sca .
        ```

## 7. Agregar un Nuevo Proyecto para Análisis Estático

Sigue estos pasos para añadir un nuevo proyecto a SonarQube sin formatear los existentes.

1.  **Exportar la contraseña de administrador:**
    ```bash
    export SONAR_ADMIN_PASSWORD="sonar_admin_password"
    ```
2.  **Ejecutar el script para añadir el proyecto:**
    Proporciona la clave (`PROJECT_KEY`) y el nombre (`PROJECT_NAME`) del nuevo proyecto.
    ```bash
    ./add-project.sh "project-key" "Nombre del Proyecto"
    ```
    *Ejemplo:*
    ```bash
    ./add-project.sh "juice-shop" "OWASP Juice Shop Test"
    ```
3.  **Exportar el nuevo token de proyecto:**
    ```bash
    export SONAR_TOKEN="tu_token_aqui"
    ```
4.  **Ejecutar el análisis estático del nuevo proyecto:**
    ```bash
    ./scan.sh sast ~/directorio/a/escanear clave_del_proyecto
    ```
    *Ejemplo:*
    ```bash
    ./scan.sh sast ~/Documentos/Pruebas/juice-shop juice-shop
    ```

## 8. Descripción de los Scripts

*   `setup.sh`: Inicia las herramientas desde cero, formatea SonarQube eliminando todos los proyectos y escaneos previos, y finalmente ejecuta los 3 tipos de análisis.
*   `scan.sh`: Realiza los escaneos de forma individual (`sast`, `dast`, `sca`).
*   `add-project.sh`: Agrega un nuevo proyecto a SonarQube para realizar un análisis estático.
*   `analyze.sh`: Ejecuta los 3 tipos de escaneo de forma escalonada sin eliminar los análisis anteriores.

## 9. FInalizar
Al finalizar desactiva la suite.
```bash
    docker compose down
```

