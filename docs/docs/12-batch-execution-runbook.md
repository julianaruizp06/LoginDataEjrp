# 12. Batch execution runbook

## Objetivo
Ejecutar el flujo batch-only de LogiData en AWS:
- subir CSV a S3 raw/local
- correr crawler raw_local
- validar tablas raw_local_*
- ejecutar CTAS curated
- ejecutar dimensiones y vista
- correr insights

## Datos base
- Perfil AWS CLI: logidata
- Región: us-east-2
- Bucket raw: ejrp-g01-raw-ejrp
- Bucket curated: ejrp-g01-curated-ejrp
- Bucket Athena results: ejrp-g01-athena-results-ejrp
- Glue crawler raw local: ejrp-g01-dev-crawler-raw-local
- Athena workgroup: ejrp-g01-dev-wg

## Paso 1. Validación de conexión AWS
### Comando
```bash
aws sts get-caller-identity --profile logidata
aws configure list --profile logidata


## Ajuste de región detectado

Durante la validación operativa se confirmó que los recursos batch del proyecto quedaron desplegados en us-east-1.

### Evidencia
- Glue databases encontradas en us-east-1:
  - logidata_raw
  - logidata_curated
- Glue crawlers encontrados en us-east-1:
  - ejrp-g01-dev-crawler-raw-local
  - ejrp-g01-dev-crawler-curated
- Athena workgroup encontrado en us-east-1:
  - ejrp-g01-dev-wg

### Decisión operativa
A partir de este punto, la ejecución batch del proyecto se realizará usando:
- región AWS CLI: us-east-1
- perfil AWS CLI: logidata

## Paso 2. Subida de CSV a S3 raw/local


### Región usada
us-east-1

### Bucket raw
ejrp-g01-raw-ejrp

### Archivos subidos
- clientes.csv
- catalogo.csv
- pedidos.csv
- entregas.csv
- sensores.csv

### Validación ejecutada
```bash
aws s3 ls s3://ejrp-g01-raw-ejrp/raw/local/ --recursive --profile logidata --region us-east-1


## Paso 3. Ejecución crawler raw_local

### Crawler ejecutado
ejrp-g01-dev-crawler-raw-local

### Resultado
- OK
- Estado observado:
  - RUNNING
  - STOPPING
  - READY

### Observaciones
El crawler terminó correctamente y quedó listo para consultar las tablas detectadas en logidata_raw.