# Fase 1 - Definir qué se queda y qué cambia

## Objetivo

Evolucionar el proyecto desde una solución funcional basada en Athena hacia una arquitectura más completa con:

- Amazon MWAA (Airflow) para orquestación
- AWS Glue Jobs con Spark para transformaciones
- Parquet en la capa curated
- Athena como capa de validación y demo
- Logs visibles en MWAA, Glue y CloudWatch
- Casos exitosos y fallidos controlados

---

## Qué se queda

Estas piezas ya son valiosas y no deben borrarse:

### Infraestructura y datos
- Buckets S3 actuales: raw, curated y athena-results
- Bases de datos: `logidata_raw` y `logidata_curated`
- Glue Catalog actual
- Estructura raw actual en S3
- Queries de validación y de negocio en Athena
- La lógica de negocio ya validada en SQL

### Rol de Athena a partir de ahora
Athena ya no será el motor principal de transformación, pero sí se mantiene para:

- validación técnica
- consultas de verificación
- queries de negocio
- demo final
- consumo analítico

---

## Qué cambia

### Orquestación
Antes:
- ejecución semi-manual con scripts

Ahora:
- MWAA / Airflow orquesta el pipeline

### Transformaciones
Antes:
- CTAS en Athena

Ahora:
- Glue Jobs con Spark generan curated

### Capa curated
Antes:
- creada por Athena

Ahora:
- escrita por Spark en Parquet sobre S3

### Observabilidad
Antes:
- logs básicos en consola y Athena

Ahora:
- logs visibles en MWAA, Glue Jobs y CloudWatch

---

## Arquitectura objetivo

\`\`\`text
S3 raw
  ↓
MWAA (Airflow)
  ↓
Glue Jobs con Spark
  ↓
S3 curated en Parquet
  ↓
Glue Catalog
  ↓
Athena
  ↓
Queries de validación y demo
\`\`\`

---

## Mapeo de transición

| Componente actual | Estado | Evolución esperada |
|---|---|---|
| Raw en S3 | Se queda | Se mantiene igual |
| Glue Catalog raw | Se queda | Se mantiene y se amplía a curated |
| Athena CTAS | Referencia legacy | Se reemplaza gradualmente por Glue Spark |
| Athena queries de negocio | Se queda | Se mantiene para demo y validación |
| Scripts manuales | Se quedan como apoyo | Se reemplazan parcialmente por Airflow |
| Capa curated actual | Referencia válida | Nueva versión será generada por Spark |
| Logs básicos | Se quedan como evidencia | Se mejoran con MWAA + Glue + CloudWatch |

---

## Nueva estructura recomendada del repo

\`\`\`text
dags/
glue_jobs/
glue_jobs/utils/
sql/validations/
sql/business_queries/
sql/legacy_athena_ctas/
docs/
scripts/
\`\`\`

---

## Qué usar como referencia funcional

La lógica actual en Athena debe usarse como contrato de negocio para reimplementar en Spark, especialmente:

- `02_ctas_pedidos_curated.sql`
- `03_ctas_sensores_curated.sql`
- `04_ctas_dimensiones.sql`

Y Athena debe conservar:

- queries de validación
- queries de negocio
- vista de demo final

---

## Siguiente paso recomendado

1. crear `glue_jobs/pedidos_curated_job.py`
2. mover la lógica de `02_ctas_pedidos_curated.sql` a Spark
3. escribir salida en Parquet en curated
4. validar el resultado con Athena
