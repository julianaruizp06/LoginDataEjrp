# Fase 2 — Ingestión

Esta fase aterriza los datos fuente en la plataforma. El objetivo no es solo “copiar archivos”, sino hacerlo con control de calidad, trazabilidad, metadata y separación clara entre batch y streaming.

---

## 1. Objetivo

Implementar la capa de ingestión para:

- datos batch desde CSV
- eventos streaming desde Kinesis
- validación básica por contrato
- quarantine de registros inválidos
- generación de manifests por lote
- aterrizaje consistente en S3 raw

---

## 2. Fuentes cubiertas

### Batch
- `clientes.csv`
- `catalogo.csv`
- `pedidos.csv`
- `entregas.csv`

### Streaming
- eventos de `sensores`
- eventos de `pedidos` cuando se simulen cambios operativos

---

## 3. Diseño de ingestión batch

## 3.1 Principio
Los CSV se leen como fuente controlada y se escriben en raw conservando estructura, fecha de ingestión y metadata mínima.

## 3.2 Metadata mínima por lote
Cada ejecución debería registrar, como mínimo:

- `source`
- `dataset`
- `ingest_ts`
- `batch_id`
- `schema_version`
- `records_read`
- `records_valid`
- `records_quarantined`

## 3.3 Layout recomendado
```text
s3://<raw-bucket>/raw/local/clientes/ingest_date=YYYY-MM-DD/
s3://<raw-bucket>/raw/local/catalogo/ingest_date=YYYY-MM-DD/
s3://<raw-bucket>/raw/local/pedidos/ingest_date=YYYY-MM-DD/
s3://<raw-bucket>/raw/local/entregas/ingest_date=YYYY-MM-DD/
```

---

## 4. Diseño de ingestión streaming

## 4.1 Kinesis Data Streams
Se usan streams separados para desacoplar dominios:

- `pedidos`
- `sensores`

## 4.2 Firehose
Firehose consume desde Kinesis y escribe en S3 raw, idealmente con prefijos por fecha.

### Ventajas
- simplifica aterrizaje continuo
- reduce necesidad de consumidor custom solo para landing
- integra buffering y manejo básico de errores

## 4.3 Layout recomendado
```text
s3://<raw-bucket>/raw/kinesis/sensores/ingest_date=YYYY-MM-DD/
s3://<raw-bucket>/raw/kinesis/pedidos/ingest_date=YYYY-MM-DD/
```

---

## 5. Validación y quarantine

## 5.1 Qué se valida en MVP
- campos requeridos
- tipos esperados
- valores permitidos para dominios cerrados

## 5.2 Qué pasa si falla
El registro no debe descartarse silenciosamente. Debe:

1. enviarse a quarantine
2. guardar motivo o motivos
3. conservar el raw original
4. quedar asociado a `batch_id`

## 5.3 Ejemplo de layout quarantine
```text
quarantine/local/pedidos/ingest_date=YYYY-MM-DD/batch_id=<id>/records.jsonl
quarantine/kinesis/sensores/ingest_date=YYYY-MM-DD/batch_id=<id>/records.jsonl
```

---

## 6. Manifests e idempotencia

Cada lote debería generar un manifest para saber exactamente qué se procesó.

### Contenido sugerido del manifest
- dataset
- source
- batch_id
- schema_version
- ingest_ts
- total_records
- valid_records
- quarantined_records
- output_path

### Beneficio
Permite re-procesar con evidencia y evita ingestiones opacas.

### Regla de idempotencia recomendada
No sobreescribir sin control. Cada batch debe poder distinguirse por:

- fecha de ingestión
- batch_id
- source
- dataset

---

## 7. Glue y catálogo en esta fase

Aunque la curación viene después, desde ingestión ya conviene preparar Glue.

### Qué hacer
- crear databases lógicas
- definir crawlers para zonas raw
- verificar que Athena puede ver las tablas

### Cuándo usar crawler
- datasets simples y repetitivos
- PoC o laboratorio académico
- cuando el esquema no cambia frecuentemente

### Cuándo preferir esquema explícito
- tablas curated críticas
- cuando se necesita mayor control de tipos
- cuando hay evolución de esquema planificada

---

## 8. Tareas concretas

1. Leer datasets desde `assets/data/raw/`.
2. Validar datasets con contratos.
3. Generar manifests por lote.
4. Escribir válidos a raw.
5. Escribir inválidos a quarantine.
6. Publicar eventos de prueba a Kinesis.
7. Confirmar aterrizaje en S3 mediante Firehose.
8. Actualizar catálogo Glue.
9. Ejecutar consultas sanity check en Athena.
10. Guardar evidencia de resultados.

---

## 9. Entradas y salidas

### Entradas
- CSV fuente
- eventos simulados
- contratos de datos
- configuración AWS y Terraform ya desplegada

### Salidas
- archivos raw en S3
- registros inválidos en quarantine
- manifests
- tablas catalogadas en Glue
- evidencia operativa y métricas

---

## 10. Errores comunes

### Error 1: cargar archivos a raw sin partición
Consecuencia: consultas más lentas y mala organización operativa.

### Error 2: usar un solo stream para todo
Consecuencia: acoplamiento innecesario y menor claridad para monitoreo.

### Error 3: perder el raw original al validar
Consecuencia: no se puede auditar por qué un registro fue rechazado.

### Error 4: no dejar evidencia del batch
Consecuencia: en sustentación no se puede demostrar control operativo.

### Error 5: depender solo del crawler para todo
Consecuencia: se pierde precisión en tipos y control del modelo analítico.

---

## 11. Criterio de cierre de la fase

La fase se considera cerrada cuando:

- los cuatro CSV principales pueden aterrizar en raw
- `pedidos` y `sensores` aplican contrato y quarantine
- existen manifests por lote
- Kinesis y Firehose aterrizan al menos un flujo de prueba
- Glue detecta datasets raw
- Athena consulta al menos una tabla raw

---

## 12. Checklist rápido

- [ ] CSV aterrizados en raw
- [ ] eventos publicados a Kinesis
- [ ] Firehose funcionando
- [ ] validación por contrato
- [ ] quarantine con razones
- [ ] manifests generados
- [ ] tablas raw visibles en Glue
- [ ] sanity checks en Athena
- [ ] evidencia guardada
