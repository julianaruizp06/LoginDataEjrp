# 07. Streaming

## Objetivo de esta capa

Procesar eventos IoT de vehículos casi en tiempo real para:
- centralizar telemetría,
- detectar anomalías de temperatura,
- aterrizar datos en el data lake,
- habilitar monitoreo y analítica posterior.

---

## 1. Flujo de streaming propuesto

### Flujo recomendado
1. Productor simula eventos desde `sensores.csv` o desde un generador simple.
2. Los eventos se publican en **Amazon Kinesis Data Streams**.
3. **Amazon Data Firehose** entrega los datos en S3 raw.
4. Glue/Athena descubren o consultan esos datos.
5. Una lógica de curación genera `sensores_curated`.
6. QuickSight o Athena explotan alertas y tendencias.

---

## 2. Servicios AWS seleccionados

### Kinesis Data Streams
Se usa para recibir eventos de sensores casi en tiempo real.

**Por qué aplica:**
- desacopla productores y consumidores,
- soporta múltiples eventos por segundo,
- es estándar para streaming sencillo en AWS.

### Kinesis Data Firehose
Se usa para entregar eventos a S3.

**Por qué aplica:**
- simplifica la persistencia,
- reduce complejidad operativa,
- evita construir un consumidor custom solo para landing raw.

### S3
Recibe los eventos en la zona raw.

### Athena / Glue
Permiten explorar y curar el histórico una vez aterrizado.

---

## 3. Evento mínimo recomendado

Formato JSON sugerido:

```json
{
  "vehiculo": "VH001",
  "timestamp": "2025-10-15 08:30:00",
  "latitud": 6.2518,
  "longitud": -75.5636,
  "temperatura": 8.7,
  "evento": "TEMP_CRITICA"
}
```

Campos esperados:
- `vehiculo`
- `timestamp`
- `latitud`
- `longitud`
- `temperatura`
- `evento`

---

## 4. Regla de anomalía

### Regla mínima
- Si `evento = 'TEMP_CRITICA'`, marcar alerta.
- Complemento opcional:
  - si `temperatura >= 8`, severidad = `ALTA`
  - si `temperatura >= 4`, severidad = `MEDIA`
  - si no, `BAJA`

Esto ya quedó reflejado en el SQL curado de sensores.

---

## 5. Simulación del streaming

### Opción recomendada para el taller
No complicar con dispositivos reales.  
Simular leyendo filas de `sensores.csv` y publicando una cada N segundos.

### Estrategia de demo
- leer lote pequeño,
- enviar 1 evento por segundo,
- mostrar llegada a raw,
- mostrar curación posterior o consulta de alertas.

---

## 6. Manejo de tardanza y checkpointing

Para el alcance actual del repo:
- **tardanza**: se documenta como riesgo, no como implementación avanzada.
- **checkpointing**: no es obligatorio si se usa Firehose como aterrizaje y luego batch-curation.

Si el panel pregunta:
> “¿Dónde manejas late events?”

Respuesta defendible:
> En esta versión del taller se priorizó un patrón híbrido: ingestión streaming hacia raw y curación analítica posterior. El manejo avanzado de late events y watermarking sería una evolución natural con Spark Structured Streaming.

---

## 7. Observabilidad del streaming

### Métricas mínimas
- eventos enviados por el productor,
- eventos rechazados,
- total de alertas críticas,
- timestamps extremos por lote.

### CloudWatch recomendado
- IncomingRecords
- DeliveryToS3.Success
- DeliveryToS3.DataFreshness

---

## 8. Qué debe existir en el repo

### Infra
- stream de Kinesis,
- delivery stream de Firehose,
- bucket raw,
- bucket quarantine o error output.

### Código
- productor para sensores,
- configuración de variables,
- evidencia de ejecución,
- consultas o CTAS sobre `sensores_curated`.

---

## 9. Qué mostrar en la sustentación

- diagrama productor -> Kinesis -> Firehose -> S3 -> Glue/Athena,
- ejemplo de evento,
- regla de anomalía,
- cómo se convierte en insight de negocio,
- diferencia entre landing streaming y análisis batch posterior.

---

## 10. Evolución futura

Mejoras naturales:
- Spark Structured Streaming,
- persistencia de alertas críticas en DynamoDB,
- notificaciones en tiempo real,
- dashboards operativos near real time.
