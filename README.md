
## 🚀 Guía de Inicio Rápido

### 1. Requisitos Previos

Asegúrate de tener instalado el siguiente software en tu sistema:
*   `git`
*   `docker`
*   `docker compose`
*   `curl`
*   `jq` (Puedes instalarlo en Debian/Ubuntu con `sudo apt-get install -y jq`)

#### Configuración del Kernel (Para Linux)
SonarQube requiere una configuración específica de memoria virtual. 

Para aplicarla de forma temporal, se tiene que ejecutar cada vez que reiniciemos el equipo y queramos ejecutar la Suite.
```bash
sudo sysctl -w vm.max_map_count=262144
```

Para aplicarla de forma permanente, se ejecuta **una vez** y la configuración se queda guardada cada que se reinicie el equipo.
```bash
echo 'vm.max_map_count=262144' | sudo tee -a /etc/sysctl.conf
```

### 2. Instalación y Configuración Inicial

Este proceso se realiza **una sola vez** para preparar todo el entorno.

1.  **Clona el repositorio:**
    ```bash
    git clone <URL_de_tu_repositorio>
    cd DevSecOps-Suite
    ```

2.  **Dale permisos de ejecución a todos los scripts:**
    ```bash
    chmod +x *.sh
    ```

3.  **Ejecuta el script de instalación inicial:**
    Este script construirá la imagen, iniciará los servicios y configurará SonarQube automáticamente.
    ```bash
    ./initial-setup.sh
    ```
4.  **¡Guarda tu Token!** Al final del proceso, el script te proporcionará un **Token de Análisis**. Cópialo y guárdalo en un lugar seguro. Lo necesitarás para ejecutar los análisis.

---

## ⚙️ Flujo de Trabajo y Uso

Una vez completada la instalación, puedes usar la suite para analizar tus proyectos.

### Flujo Principal: Análisis Completo y Automático

Este es el método recomendado para un análisis completo. El script `analyze.sh` ejecuta SCA, SAST y DAST en secuencia.

1.  **Inicia los servicios de fondo** (si no están corriendo):
    ```bash
    docker compose up -d
    ```

2.  **Exporta tu Token de Análisis:**
    (Reemplaza `tu_token_aqui` con el token que guardaste durante la instalación o al crear un nuevo proyecto).
    ```bash
    export SONAR_TOKEN="tu_token_aqui"
    ```

3.  **Ejecuta el análisis completo:**
    El script requiere dos argumentos: la ruta al proyecto y la clave del proyecto en SonarQube.
    ```bash
    ./analyze.sh <ruta_al_proyecto> <sonar_project_key>
    ```
    **Ejemplo con Juice Shop:**
    ```bash
    ./analyze.sh ~/Documentos/Pruebas/juice-shop juice-shop
    ```

### Gestión de Proyectos en SonarQube

Puedes añadir nuevos proyectos a SonarQube sin tener que reiniciar todo.

1.  **Exporta la contraseña de administrador** (la que definiste en `setup.sh`, por defecto es `sonar_admin_password`):
    ```bash
    export SONAR_ADMIN_PASSWORD="sonar_admin_password"
    ```

2.  **Ejecuta el script `add-project.sh`:**
    Pásale la nueva clave de proyecto y el nombre visible entre comillas.
    ```bash
    ./add-project.sh <nueva_project_key> "<Nombre del Nuevo Proyecto>"
    ```
    **Ejemplo:**
    ```bash
    ./add-project.sh mi-app-web "Mi Aplicación Web de Cliente"
    ```
    El script te devolverá un **nuevo token** para este proyecto.

### Uso Avanzado: Análisis Individuales

El script `scan.sh` te permite ejecutar cada análisis por separado.

#### Análisis de Dependencias (SCA)
```bash
# Navega al directorio del proyecto y ejecuta:
~/DevSecOps-Suite/scan.sh sca .
```

#### Análisis Estático (SAST)
```bash
# Exporta el token del proyecto a analizar
export SONAR_TOKEN="token_del_proyecto_especifico"

# Ejecuta el escaneo con sus 3 argumentos
./scan.sh sast <ruta_al_proyecto> <clave_del_proyecto>
```
**Ejemplo:**
```bash
./scan.sh sast ~/Documentos/Pruebas/juice-shop juice-shop
```

#### Análisis Dinámico (DAST)
1.  **Inicia tu aplicación en un contenedor**, conectándola a la red de la suite:
    ```bash
    docker run -d --rm --name mi-app-dast --network=devsecops-suite_devsecops-net mi-app-imagen
    ```
2.  **Ejecuta el escaneo DAST:**
    ```bash
    ./scan.sh dast http://mi-app-dast:puerto
    ```
3.  **Detén el contenedor de tu aplicación** cuando termines:
    ```bash
    docker stop mi-app-dast
    ```

---

## 📊 Visualización de Resultados

*   **Análisis SCA (Trivy):** Los resultados se muestran **directamente en la terminal** al finalizar el escaneo.
*   **Análisis SAST (SonarQube):** Los resultados se consultan en el dashboard web, accesible en `http://localhost:9000`.
*   **Análisis DAST (OWASP ZAP):** Se genera un informe `zap_report.html` dentro de la carpeta `reports` en el directorio de la suite.

## 🗂️ Descripción de los Scripts

| Script           | Descripción                                                                                                             |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------- |
| `setup.sh`       | **Instalación inicial.** Construye la imagen, inicia los servicios y aprovisiona SonarQube por primera vez. Borra datos. |
| `analyze.sh`     | **Orquestador principal.** Ejecuta SCA, SAST y DAST en secuencia sobre un proyecto. No borra datos.                       |
| `scan.sh`        | **Herramienta individual.** Permite ejecutar un único tipo de análisis (sast, sca, o dast).                              |
| `add-project.sh` | **Gestión de proyectos.** Añade un nuevo proyecto a una instancia de SonarQube ya configurada y genera un nuevo token.    |
| `teardown.sh`    | **Apagado.** Detiene y elimina los contenedores de servicios de fondo (SonarQube, PostgreSQL) para liberar recursos.      |
