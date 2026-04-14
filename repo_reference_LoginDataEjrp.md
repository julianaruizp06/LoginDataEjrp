# Referencia técnica del repositorio `LoginDataEjrp`

## 1. Propósito del repositorio

Este repositorio implementa una solución de ingeniería de datos en AWS para **LogiData S.A.S.**, con una arquitectura orientada a cargas **batch** y **streaming**. La estructura del proyecto está organizada para separar claramente:

- documentación funcional y técnica,
- infraestructura como código con Terraform,
- scripts operativos,
- SQL analítico para Athena,
- código fuente Python,
- pruebas,
- datos de ejemplo y evidencia.

---

## 2. Estructura principal

En la rama de referencia, la estructura principal del repositorio es la siguiente:

```text
.github/
.vscode/
assets/
diagrams/
docs/
evidence/
infra/
scripts/
sql/
src/
tests/
.env.example
.gitattributes
.gitignore
LICENSE
Makefile
README.md
pytest.ini
requirements.txt
```

---

## 3. Descripción de cada carpeta raíz

### `.github/workflows`
Contiene los workflows de automatización de GitHub Actions.

#### Archivo presente
- `ci.yml`: pipeline de integración continua para validaciones automáticas, checks o pruebas al hacer push o pull request.

---

### `.vscode`
Contiene configuración local del workspace para Visual Studio Code.

#### Archivo presente
- `settings.json`: ajustes del editor para estandarizar formato, comportamiento o validaciones locales.

---

### `assets/data`
Contiene archivos de datos base usados como insumo local del proyecto.

#### Subestructura
- `expected/`
- `raw/`

#### Archivos presentes
- `assets/data/expected/counts_expected.json`: resultados esperados para validaciones o comparaciones.
- `assets/data/raw/catalogo.csv`: dataset raw de catálogo.
- `assets/data/raw/clientes.csv`: dataset raw de clientes.
- `assets/data/raw/diccionario_datos.csv`: diccionario de datos fuente.
- `assets/data/raw/entregas.csv`: dataset raw de entregas.
- `assets/data/raw/pedidos.csv`: dataset raw de pedidos.
- `assets/data/raw/sensores.csv`: dataset raw de sensores.

#### Rol
Esta carpeta soporta pruebas, simulaciones y validaciones del pipeline de ingestión.

---

### `diagrams`
Contiene los diagramas de arquitectura y flujo de datos.

#### Archivos presentes
- `architecture.drawio`: fuente editable del diagrama de arquitectura.
- `architecture.png`: versión exportada del diagrama de arquitectura.
- `data-flow.png`: diagrama de flujo de datos.

#### Rol
Permite documentar visualmente el diseño técnico de la solución.

---

### `docs`
Contiene la documentación funcional, técnica y operativa del proyecto.

#### Archivos presentes
- `00-overview.md`
- `01-phase-1-foundations.md`
- `02-phase-2-ingestion.md`
- `03-phase-3-curation.md`
- `04-phase-4-governance.md`
- `observability.md`
- `quarantine-policy.md`
- `schema-evolution.md`
- `troubleshooting.md`

#### Subcarpeta
- `docs/data-contracts/`
  - `pedidos.v1.json`
  - `sensores.v1.json`

#### Qué hace cada documento
- **`00-overview.md`**: visión general del proyecto.
- **`01-phase-1-foundations.md`**: fundamentos iniciales de arquitectura y setup.
- **`02-phase-2-ingestion.md`**: capa de ingestión.
- **`03-phase-3-curation.md`**: transformación y curación de datos.
- **`04-phase-4-governance.md`**: gobierno de datos.
- **`observability.md`**: logging, monitoreo y métricas.
- **`quarantine-policy.md`**: política de manejo de registros inválidos o en cuarentena.
- **`schema-evolution.md`**: tratamiento de cambios de esquema.
- **`troubleshooting.md`**: guía de soporte y resolución de problemas.
- **`data-contracts/*.json`**: contratos de datos versionados para entidades del sistema.

---

### `evidence`
Carpeta destinada a almacenar evidencias operativas del proyecto.

#### Subestructura
- `logs/`
- `monitoring/`
- `samples/`
- `README.md`

#### Rol
Sirve para guardar muestras, evidencia de ejecución, logs y material de respaldo para pruebas o entregables.

---

### `infra/terraform`
Contiene la infraestructura como código del proyecto.

#### Subestructura principal
- `bootstrap/`
- `envs/`
- `modules/`

---

## 4. Terraform: detalle por carpeta

### 4.1 `infra/terraform/bootstrap`
Esta carpeta crea la infraestructura mínima necesaria para que Terraform use backend remoto en AWS.

#### Archivos presentes
- `main.tf`
- `outputs.tf`
- `providers.tf`
- `variables.tf`

#### Qué hace
Crea:
- un bucket S3 para almacenar el estado remoto (`tfstate`),
- una tabla DynamoDB para locks (`tflock`).

#### Configuración por archivo

##### `providers.tf`
Define:
- versión mínima de Terraform,
- provider AWS,
- región tomada desde `var.region`.

##### `variables.tf`
Declara las variables de entrada:
- `region`
- `prefix`
- `group`

##### `main.tf`
Hace lo siguiente:
- obtiene el AWS Account ID actual,
- construye el nombre del bucket de estado,
- construye el nombre de la tabla de locks,
- crea el bucket S3,
- activa versionado,
- bloquea acceso público,
- habilita cifrado server-side,
- crea la tabla DynamoDB para locking.

##### `outputs.tf`
Expone:
- `state_bucket_name`
- `lock_table_name`

---

### 4.2 `infra/terraform/envs`
Contiene la definición por ambiente.

#### Ambientes presentes
- `dev/`
- `prod/`

Cada ambiente contiene:
- `backend.tf`
- `main.tf`
- `outputs.tf`
- `providers.tf`
- `terraform.tfvars`
- `variables.tf`

#### Rol general
Estas carpetas no crean recursos directamente con lógica repetida; ensamblan módulos reutilizables y les pasan configuración.

---

### 4.2.1 `backend.tf`
Contiene la definición del backend remoto S3 sin valores embebidos:

```hcl
terraform {
  backend "s3" {}
}
```

#### Implicación
Los valores reales del backend se deben pasar en `terraform init` usando `-backend-config`.

---

### 4.2.2 `terraform.tfvars`
Archivo de parametrización del ambiente.

#### Variables que contiene
- `project`
- `prefix`
- `group`
- `environment`
- `region`
- `bucket_suffix`

#### Configuración actual aplicada

##### `dev`
```hcl
project       = "logidata"
prefix        = "ejrp"
group         = "01"
environment   = "dev"
region        = "us-east-1"
bucket_suffix = "ejrp"
```

##### `prod`
```hcl
project       = "logidata"
prefix        = "ejrp"
group         = "01"
environment   = "prod"
region        = "us-east-1"
bucket_suffix = "ejrp"
```

#### Significado de cada variable
- **`project`**: nombre lógico del proyecto.
- **`prefix`**: prefijo principal para nombrar recursos.
- **`group`**: identificador de grupo o equipo.
- **`environment`**: ambiente (`dev` o `prod`).
- **`region`**: región AWS objetivo.
- **`bucket_suffix`**: sufijo adicional para nombres de buckets.

---

### 4.2.3 `main.tf`
Ensamble principal del ambiente.

#### Módulos conectados
- `naming`
- `s3`
- `iam`
- `kinesis`
- `firehose`
- `athena`
- `glue`

#### Flujo de alto nivel
1. Se generan nombres y tags comunes.
2. Se crean buckets S3.
3. Se crean roles IAM.
4. Se crean streams Kinesis.
5. Se configura Firehose.
6. Se configura Athena.
7. Se configura Glue.

---

### 4.2.4 `providers.tf`
Configura el provider AWS del ambiente.

#### Rol
Asegura que Terraform opere contra la región definida en variables y con la versión del provider soportada por el proyecto.

---

### 4.2.5 `variables.tf`
Declara las variables que el ambiente necesita para operar.

#### Rol
Sirve como contrato de entrada para `main.tf` y para el uso de `terraform.tfvars`.

---

### 4.2.6 `outputs.tf`
Expone outputs relevantes del ambiente.

#### Rol
Permite inspeccionar valores finales generados por el despliegue, como nombres o referencias a recursos.

---

## 5. Terraform: detalle de módulos

La carpeta `infra/terraform/modules` contiene módulos reutilizables.

### Módulos presentes
- `athena/`
- `firehose/`
- `glue/`
- `iam/`
- `kinesis/`
- `lakeformation/`
- `naming/`
- `s3/`

---

### 5.1 `modules/naming`
Centraliza la convención de nombres y tags del proyecto.

#### Archivos presentes
- `locals.tf`
- `outputs.tf`
- `variables.tf`

#### Qué hace
Construye nombres estandarizados para recursos y define tags comunes.

#### Lógica principal
A partir de variables como `prefix`, `group`, `environment` y `bucket_suffix`, genera:
- `resource_prefix`
- `raw_bucket_name`
- `curated_bucket_name`
- `athena_results_bucket_name`
- tags consistentes para todos los recursos

#### Resultado con la configuración actual
Con:

```hcl
project       = "logidata"
prefix        = "ejrp"
group         = "01"
environment   = "dev"
region        = "us-east-1"
bucket_suffix = "ejrp"
```

se derivan nombres como:
- `resource_prefix = ejrp-g01-dev`
- `raw_bucket_name = ejrp-g01-raw-ejrp`
- `curated_bucket_name = ejrp-g01-curated-ejrp`
- `athena_results_bucket_name = ejrp-g01-athena-results-ejrp`

Y para bootstrap:
- `state bucket = ejrp-g01-tfstate-<AWS_ACCOUNT_ID>`
- `lock table = ejrp-g01-tflock`

---

### 5.2 `modules/s3`
Maneja la creación de buckets S3 del proyecto.

#### Archivos presentes
- `main.tf`
- `outputs.tf`
- `variables.tf`

#### Rol
Crear y exponer buckets del lago de datos y buckets auxiliares.

---

### 5.3 `modules/iam`
Maneja roles y políticas IAM.

#### Archivos presentes
- `main.tf`
- `outputs.tf`
- `variables.tf`

#### Rol
Crear permisos y roles requeridos por servicios como Firehose, Glue, Athena u otros componentes.

---

### 5.4 `modules/kinesis`
Maneja la capa de streaming basada en Kinesis.

#### Archivos presentes
- `main.tf`
- `outputs.tf`
- `variables.tf`

#### Rol
Crear los streams de eventos usados por la solución.

---

### 5.5 `modules/firehose`
Configura la entrega de eventos hacia almacenamiento.

#### Archivos presentes
- `main.tf`
- `outputs.tf`
- `variables.tf`

#### Rol
Tomar streaming de entrada y enviarlo hacia destinos de almacenamiento, normalmente S3.

---

### 5.6 `modules/athena`
Configura recursos necesarios para Athena.

#### Archivos presentes
- `main.tf`
- `outputs.tf`
- `variables.tf`

#### Rol
Habilitar consultas analíticas y exponer configuraciones relacionadas con resultados o integración.

---

### 5.7 `modules/glue`
Configura componentes de Glue.

#### Archivos presentes
- `main.tf`
- `outputs.tf`
- `variables.tf`

#### Rol
Manejar catálogo de datos, metadatos y soporte a datasets analíticos.

---

### 5.8 `modules/lakeformation`
Prepara componentes asociados a gobierno del lago de datos.

#### Archivos presentes
- `main.tf`
- `outputs.tf`
- `variables.tf`

#### Rol
Extender control de acceso y gobierno sobre activos de datos, si se habilita dentro del flujo.

---

## 6. Carpeta `scripts`

Contiene scripts PowerShell de operación y automatización.

### Archivos presentes
- `run_streaming.ps1`
- `run_validations.ps1`
- `seed_batch_to_s3.ps1`
- `setup_infra_completa_ejrp.ps1`
- `tf_apply.ps1`
- `tf_destroy.ps1`
- `tf_init.ps1`
- `tf_plan.ps1`

### Qué hace cada uno
- **`tf_init.ps1`**: inicializa Terraform.
- **`tf_plan.ps1`**: ejecuta `terraform plan`.
- **`tf_apply.ps1`**: ejecuta `terraform apply`.
- **`tf_destroy.ps1`**: destruye infraestructura.
- **`run_streaming.ps1`**: dispara el flujo de streaming.
- **`run_validations.ps1`**: corre validaciones del proyecto.
- **`seed_batch_to_s3.ps1`**: carga datos batch hacia S3.
- **`setup_infra_completa_ejrp.ps1`**: script de setup general de la solución.

---

## 7. Carpeta `sql/athena`

Contiene los scripts SQL usados en Athena.

### Archivos presentes
- `00_create_databases.sql`
- `01_raw_sanity_checks.sql`
- `02_ctas_pedidos_curated.sql`
- `03_ctas_sensores_curated.sql`
- `04_ctas_dimensiones.sql`
- `05_view_pedidos_unificados.sql`
- `06_insights.sql`

### Qué hace cada uno
- **`00_create_databases.sql`**: crea bases o esquemas iniciales.
- **`01_raw_sanity_checks.sql`**: ejecuta controles de calidad sobre datos raw.
- **`02_ctas_pedidos_curated.sql`**: crea tablas curadas de pedidos mediante CTAS.
- **`03_ctas_sensores_curated.sql`**: crea tablas curadas de sensores mediante CTAS.
- **`04_ctas_dimensiones.sql`**: crea tablas dimensionales.
- **`05_view_pedidos_unificados.sql`**: crea una vista unificada de pedidos.
- **`06_insights.sql`**: contiene consultas de análisis final o KPIs.

---

## 8. Carpeta `src`

Contiene el código fuente Python del proyecto.

### Estructura
- `config/`
- `ingest/`
- `observability/`
- `producers/`
- `validators/`
- `__init__.py`

---

### 8.1 `src/config`
#### Archivo presente
- `settings.py`

#### Rol
Centraliza configuración compartida del proyecto, como constantes, parámetros o variables de entorno.

---

### 8.2 `src/ingest`
#### Archivos presentes
- `__init__.py`
- `manifest.py`
- `quarantine_writer.py`
- `reader_csv.py`
- `validator.py`

#### Rol esperado
- **`manifest.py`**: gestiona manifiestos o metadatos de ingestión.
- **`quarantine_writer.py`**: mueve registros inválidos a cuarentena.
- **`reader_csv.py`**: lee archivos CSV de entrada.
- **`validator.py`**: ejecuta validaciones sobre los datos de entrada.

---

### 8.3 `src/observability`
#### Archivos presentes
- `__init__.py`
- `logger.py`
- `metrics.py`

#### Rol esperado
- **`logger.py`**: logging estructurado.
- **`metrics.py`**: métricas operativas y de monitoreo.

---

### 8.4 `src/producers`
#### Archivos presentes
- `common.py`
- `stream_pedidos.py`
- `stream_sensores.py`

#### Rol esperado
- **`common.py`**: utilidades compartidas para productores.
- **`stream_pedidos.py`**: productor de eventos de pedidos.
- **`stream_sensores.py`**: productor de eventos de sensores.

---

### 8.5 `src/validators`
#### Archivos presentes
- `validate_athena_queries.py`
- `validate_glue_catalog.py`
- `validate_s3_raw.py`

#### Rol esperado
- validar consultas Athena,
- validar catálogo de Glue,
- validar contenido raw en S3.

---

## 9. Carpeta `tests`

Contiene pruebas automáticas del proyecto.

### Estructura
- `integration/`
- `unit/`
- `test_quarantine.py`
- `test_validator.py`

### Rol
- **`integration/`**: pruebas integradas entre componentes.
- **`unit/`**: pruebas unitarias.
- **`test_quarantine.py`**: valida comportamiento de cuarentena.
- **`test_validator.py`**: valida reglas de validación.

---

## 10. Archivos raíz

### `.env.example`
Ejemplo de variables de entorno requeridas por el proyecto.

### `.gitattributes`
Configuración de atributos de Git para manejo de archivos.

### `.gitignore`
Define archivos y carpetas que Git no debe versionar.

### `LICENSE`
Archivo de licencia del proyecto.

### `Makefile`
Atajos para ejecutar tareas repetitivas del proyecto.

### `README.md`
Documento principal de presentación y uso general del repositorio.

### `pytest.ini`
Configuración base de pytest para pruebas Python.

### `requirements.txt`
Lista de dependencias Python del proyecto.

---

## 11. Configuración aplicada hasta este punto

La parametrización principal que ya quedó ajustada es la de Terraform para usar el prefijo `ejrp`.

### Valores actualmente establecidos

#### `dev`
```hcl
project       = "logidata"
prefix        = "ejrp"
group         = "01"
environment   = "dev"
region        = "us-east-1"
bucket_suffix = "ejrp"
```

#### `prod`
```hcl
project       = "logidata"
prefix        = "ejrp"
group         = "01"
environment   = "prod"
region        = "us-east-1"
bucket_suffix = "ejrp"
```

### Qué implica esto
- Los nombres de recursos se construyen de forma consistente desde variables.
- No fue necesario cambiar la arquitectura base del repo.
- El módulo `naming` mantiene la convención centralizada.
- `backend.tf` permanece genérico y el backend se pasa por `terraform init`.

---

## 12. Resumen final

Hasta este punto, el repositorio ya quedó:

- estructurado con la arquitectura prevista,
- documentado por capas,
- parametrizado para `dev` y `prod`,
- preparado para bootstrap de Terraform,
- alineado a una convención de nombres basada en `prefix = ejrp`.

El siguiente paso operativo natural es habilitar correctamente la ejecución local de Terraform en Windows y luego correr `bootstrap`, seguido por `init/plan/apply` en el ambiente `dev`.
