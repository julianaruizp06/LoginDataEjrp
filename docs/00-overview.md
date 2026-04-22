# LogiData Lakehouse (EJRP) — Overview

## 1. Contexto y objetivo

LogiData S.A.S. requiere centralizar datos operativos y eventos de sensores que actualmente se encuentran dispersos en archivos estructurados y fuentes heterogéneas.

El objetivo del proyecto es construir una arquitectura tipo Lakehouse en AWS que permita:

- centralizar datos raw y curated en S3
- aplicar transformaciones y validaciones con Glue Jobs sobre Spark
- consultar datos mediante Athena
- orquestar pipelines con Airflow
- separar claramente datos válidos y datos rechazados (quarantine)
- habilitar una base confiable para dashboards y analítica

## 2. Alcance actual del repositorio

El estado implementado y validado del proyecto se concentra en los siguientes componentes:

- S3 como storage principal
- Glue Catalog para metadatos
- Glue Jobs para procesamiento y curación
- Athena para consulta analítica
- Airflow local con Docker Compose para orquestación
- Terraform para definición de infraestructura

## 3. Flujo de alto nivel

Fuentes raw -> S3 raw -> Glue Catalog -> Glue Jobs -> curated / quarantine -> Athena -> consumo analítico

## 4. Capas de datos

### Raw
Zona de aterrizaje de datos sin transformar.

### Curated
Zona de datos validados, tipados y listos para análisis.

### Quarantine
Zona de registros inválidos o rechazados por reglas de calidad.

### Consumption
Consultas analíticas y soporte a dashboards a través de Athena.

## 5. Componentes del proyecto

### Terraform
Define y despliega infraestructura AWS de forma reproducible.

### Glue Jobs
Transforman datos raw hacia curated y quarantine.

### Athena
Permite consultar datos sobre S3 sin moverlos a otro motor.

### Airflow
Coordina la ejecución de validaciones, Glue Jobs y queries de control.

## 6. Estado actual del enfoque arquitectónico

El enfoque vigente y prioritario del proyecto es el Lakehouse sobre AWS.
Los documentos complementarios de bases relacionales o NoSQL deben interpretarse como extensiones o propuestas, no como el núcleo principal ya desplegado del repositorio.

## 7. Documentos recomendados para continuar la lectura

- `01-phase-1-foundations.md`
- `02-phase-2-ingestion.md`
- `03-phase-3-curation.md`
- `04-phase-4-governance.md`
- `05-relational-nosql.md`
- `06-data-warehouse.md`
- `08-dataops-quality.md`
- `09-dashboard-quicksight.md`
- `10-sustentacion.md`
- `observability.md`
- `quarantine-policy.md`
- `schema-evolution.md`
- `troubleshooting.md`
