# Glue Jobs con Spark

En esta carpeta se encuentran los jobs de AWS Glue desarrollados con PySpark, responsables de transformar los datos desde la capa raw hacia curated y quarantine, aplicando validaciones de calidad y lógica de negocio.

---

## Propósito

Los Glue Jobs cumplen las siguientes funciones:

- Procesar datos provenientes de la capa raw (S3 + Glue Catalog)
- Aplicar validaciones de calidad de datos
- Separar datos en:
  - Curated (válidos)
  - Quarantine (inválidos)
- Enriquecer datos mediante joins con otras fuentes
- Generar datasets listos para consumo analítico en Athena o herramientas BI

---

## Arquitectura de ejecución

S3 (raw) → Glue Catalog → Glue Job (Spark)  
                             ↓  
             Validaciones + Transformaciones  
                             ↓  
     Curated (válidos)    Quarantine (errores)  
             ↓                     ↓  
     Athena / BI        Debug / Data Quality  

---

## Jobs disponibles

### 1. pedidos_curated_job.py

#### Descripción
Procesa pedidos desde múltiples fuentes y aplica validaciones avanzadas de negocio.

#### Flujo

1. Lectura de tablas raw:
   - pedidos
   - entregas
   - clientes
   - catalogo

2. Transformaciones:
   - Normalización de monto
   - Conversión de fechas
   - Renombrado de columnas

3. Enriquecimiento:
   - Joins entre entidades

4. Validaciones:
   - Campos obligatorios
   - Monto válido (no nulo, no negativo)
   - Estados válidos
   - Integridad referencial (cliente/producto)
   - Consistencia operativa (entregas)
   - Detección de duplicados

5. Output:
   - curated/pedidos_curated/
   - quarantine/pedidos_curated/

#### Casos de uso

- KPI de ventas
- Análisis de cumplimiento de entregas
- Data Quality tracking

---

### 2. sensores_curated_job.py

#### Descripción
Procesa datos de sensores IoT relacionados con condiciones de transporte.

#### Transformaciones principales

- Conversión de timestamps
- Derivación de fechas (event_date, periodo_ym)
- Flags de temperatura crítica
- Clasificación de severidad:
  - BAJA
  - NORMAL
  - ALTA

#### Output

- curated/sensores_curated/

#### Casos de uso

- Monitoreo de temperatura
- Detección de anomalías logísticas

---

### 3. dimensions_job.py

#### Descripción
Genera tablas dimensionales para analítica (modelo tipo star schema).

#### Dimensiones generadas

- dim_cliente
- dim_producto
- dim_vehiculo
- dim_fecha

#### Objetivo

- Estandarizar entidades
- Optimizar consultas en Athena
- Soportar dashboards en BI

---

## Parámetros de ejecución

Todos los jobs reciben:

```json
{
  "--RAW_DB": "logidata_raw",
  "--CURATED_BUCKET": "ejrp-g01-curated-ejrp"
}

Ejecución desde CLI
aws glue start-job-run \
  --job-name pedidos-curated-job \
  --arguments '{
    "--RAW_DB":"logidata_raw",
    "--CURATED_BUCKET":"ejrp-g01-curated-ejrp"
  }' \
  --region us-east-1
  
Buenas prácticas implementadas
Validaciones explícitas de schema
Separación curated vs quarantine
Uso de overwrite controlado
Tipado consistente para Athena
Logs detallados para debugging
Manejo de datos inconsistentes (ej: monto estructurado)