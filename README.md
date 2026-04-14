# LogiData Lakehouse (EJRP)

Solución de ingeniería de datos en AWS para **LogiData S.A.S.**, orientada a integrar información **batch** (CSV) y **streaming** (eventos IoT) en una arquitectura moderna de datos con foco en trazabilidad, gobierno, calidad y analítica.

> Estado del repositorio: **foundation / architecture skeleton** con infraestructura base, contratos de datos, validación, quarantine, observabilidad mínima y estructura por fases. Este documento deja trazada la ruta para completar el taller end-to-end.

---

## 1. Objetivo del proyecto

Construir una plataforma de datos en AWS que permita:

- centralizar datos operativos dispersos
- soportar ingestión batch y streaming
- validar y controlar calidad desde el ingreso
- curar datos para consulta analítica
- habilitar dashboards y KPIs para operación logística
- dejar una base gobernada, reproducible y defendible en una sustentación técnica

---

## 2. Problema de negocio

LogiData procesa pedidos y eventos operativos de última milla. Actualmente la información proviene de archivos CSV, procesos manuales y señales IoT de vehículos. Esto genera:

- datos fragmentados
- poca trazabilidad de origen
- dificultad para medir cumplimiento operativo
- baja capacidad de reacción ante anomalías
- alto riesgo de inconsistencias entre fuentes

La propuesta resuelve esto con un **lakehouse liviano en AWS** usando S3 como fuente de verdad, Kinesis para streaming, Glue para catálogo, Athena para consulta, y componentes de validación, quarantine y evidencia técnica.

---

## 3. Arquitectura objetivo

### Componentes principales

- **S3**: zonas `raw`, `curated`, `quarantine` y `_system`
- **Kinesis Data Streams**: recepción de eventos de `pedidos` y `sensores`
- **Kinesis Firehose**: entrega continua desde streaming hacia S3 raw
- **Glue Data Catalog + Crawlers**: registro de metadatos y descubrimiento de datasets
- **Athena**: consultas SQL, validación e insights
- **Terraform**: provisión reproducible de infraestructura
- **Python**: validación, manifests, quarantine y automatizaciones del proyecto
- **GitHub Actions**: checks de CI para calidad de código e infraestructura

### Flujo de alto nivel

1. Los CSV se reciben como fuente batch.
2. Los eventos IoT y operativos se publican en Kinesis.
3. Firehose aterriza eventos en S3 raw.
4. Los contratos de datos validan estructura y reglas mínimas.
5. Los registros inválidos van a quarantine.
6. Glue cataloga los datasets.
7. Athena y/o Spark construyen datasets curados y vistas analíticas.
8. Los resultados se consumen en análisis, evidencia y dashboard.

---

## 4. Estructura del repositorio

```text
.github/                 # CI
assets/data/             # datos fuente y expected results
diagrams/                # diagramas de arquitectura y flujo
docs/                    # documentación por fases
evidence/                # logs, samples, métricas y evidencia operativa
infra/terraform/         # bootstrap, ambientes y módulos AWS
scripts/                 # helpers operativos PowerShell
sql/athena/              # SQL analítico y CTAS
src/                     # validadores, readers, manifests, quarantine, producers
tests/                   # pruebas unitarias e integración
```

---

## 5. Fases del proyecto

### Fase 1 — Foundations
Objetivo: dejar base técnica, naming, layout S3, contratos, políticas y bootstrap de infraestructura.

Entregables:
- arquitectura documentada
- naming estándar
- layout del data lake
- contratos de datos v1
- política de quarantine
- observabilidad mínima
- bootstrap Terraform

### Fase 2 — Ingestión
Objetivo: llevar datos batch y streaming a raw de forma controlada.

Entregables:
- ingestión de CSV
- publicación a Kinesis
- Firehose hacia S3 raw
- manifests por lote
- validación y quarantine

### Fase 3 — Curación
Objetivo: transformar raw en datasets analíticos reutilizables.

Entregables:
- tablas curated en Athena/S3
- joins entre pedidos, entregas, clientes y catálogo
- vistas para KPIs
- particionado analítico
- primeras consultas de negocio

### Fase 4 — Consumo y gobierno
Objetivo: dejar el proyecto defendible y operativo.

Entregables:
- catálogo consultable
- controles de acceso
- monitoreo y evidencia
- evolución de esquema
- documentación de troubleshooting
- base para dashboard y sustentación

---

## 6. Datasets del caso

### Batch
- `clientes.csv`
- `catalogo.csv`
- `pedidos.csv`
- `entregas.csv`

### Streaming / IoT
- `sensores.csv` como base de simulación
- eventos publicados a Kinesis para sensores y pedidos

---

## 7. Convenciones principales

### Naming lógico
- prefijo recomendado: `ejrp`
- grupo: `g01`
- ambientes: `dev`, `prod`
- región sugerida: `us-east-1`

### Buckets
- `*-raw-*`
- `*-curated-*`
- `*-athena-results-*`

### Layout S3
```text
s3://<raw-bucket>/raw/<source>/<dataset>/ingest_date=YYYY-MM-DD/
s3://<curated-bucket>/curated/<domain>/<dataset>/event_date=YYYY-MM-DD/
s3://<raw-bucket>/quarantine/<source>/<dataset>/ingest_date=YYYY-MM-DD/batch_id=<id>/
s3://<raw-bucket>/_system/metadata/manifests/<dataset>/manifest_<batch_id>.json
```

---

## 8. Cómo ejecutar el proyecto

## 8.1 Requisitos previos
- cuenta AWS con permisos sobre S3, IAM, Kinesis, Glue y Athena
- Terraform instalado
- Python 3.11 o similar
- credenciales AWS configuradas
- Git y VS Code recomendados

## 8.2 Flujo recomendado
1. Inicializar bootstrap de Terraform.
2. Inicializar ambiente `dev`.
3. Aplicar infraestructura.
4. Cargar o simular datos batch.
5. Ejecutar validaciones.
6. Confirmar manifests, quarantine y evidencias.
7. Ejecutar queries Athena.
8. Generar screenshots y material de sustentación.

---

## 9. Definition of Done del repositorio

Para considerar este repositorio listo para sustentar, debe cumplir al menos lo siguiente:

- infraestructura `dev` desplegable por Terraform
- datasets raw aterrizados y trazables
- contratos de datos aplicados al menos a `pedidos` y `sensores`
- registros inválidos enviados a quarantine
- Glue catalogando datasets consumibles
- consultas Athena ejecutables
- evidencia de logs, métricas y screenshots
- documentación de fases completa
- troubleshooting suficiente para reproducir demo

---

## 10. Próximos incrementos recomendados

Aunque este repositorio ya tiene una base sólida, los siguientes incrementos lo dejan realmente end-to-end:

- agregar RDS PostgreSQL para modelo relacional
- agregar DynamoDB para eventos de sensores o estado reciente
- completar CTAS y vistas analíticas
- agregar DAGs de orquestación
- incorporar validaciones de calidad más ricas
- formalizar dashboard final en QuickSight

---

## 11. Documentos relacionados

- `docs/00-overview.md`
- `docs/01-phase-1-foundations.md`
- `docs/02-phase-2-ingestion.md`
- `docs/03-phase-3-curation.md`
- `docs/04-phase-4-governance.md`
- `docs/observability.md`
- `docs/quarantine-policy.md`
- `docs/schema-evolution.md`
- `docs/troubleshooting.md`
