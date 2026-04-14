# Fase 3 — Curación

Esta fase transforma la información raw en datasets consistentes, consultables y orientados a negocio. Aquí empieza a materializarse el valor analítico del proyecto.

---

## 1. Objetivo

Construir la capa curated para:

- limpiar y estandarizar datos
- unir datasets operativos relacionados
- generar datasets analíticos reutilizables
- optimizar consulta con formato columnar y particiones
- habilitar KPIs de operación logística

---

## 2. Principios de curación

- conservar raw como fuente de verdad
- no escribir lógica de negocio irreversible sobre raw
- estandarizar tipos de fecha, estados y llaves
- dejar datasets con nombres claros y reutilizables
- preferir formatos analíticos como Parquet

---

## 3. Datasets curated recomendados

## 3.1 pedidos_curated
Objetivo: consolidar pedidos válidos con atributos listos para análisis.

Campos sugeridos:
- id_pedido
- id_cliente
- id_producto
- fecha
- monto
- estado
- event_date
- ingest_date

## 3.2 sensores_curated
Objetivo: normalizar eventos de sensores y dejar lista la analítica de anomalías.

Campos sugeridos:
- vehiculo
- timestamp
- latitud
- longitud
- temperatura
- evento
- event_date

## 3.3 pedidos_unificados
Objetivo: unir pedidos, clientes, catálogo y entregas para análisis de cumplimiento.

Campos sugeridos:
- id_pedido
- fecha_pedido
- zona_cliente
- tipo_cliente
- categoria_producto
- tipo_entrega
- monto
- estado_pedido
- hora_programada
- hora_real
- vehiculo
- conductor
- indicador_entrega_a_tiempo
- minutos_retraso
- event_date

---

## 4. Modelo analítico mínimo

Para el taller, el mínimo defendible es un modelo tipo estrella liviano.

### Dimensiones sugeridas
- `dim_cliente`
- `dim_producto`
- `dim_tiempo`
- `dim_vehiculo`
- `dim_zona`

### Hecho sugerido
- `fact_pedidos_entregas`

### Métricas mínimas
- cantidad de pedidos
- monto total
- pedidos cancelados
- pedidos entregados
- entregas a tiempo
- retraso promedio
- cantidad de alertas de temperatura crítica

---

## 5. Tecnología de curación

## Opción A — Athena CTAS
Útil para el alcance actual del repositorio.

Ventajas:
- rápida de implementar
- ideal para volumen académico
- aprovecha Glue + Athena ya presentes

## Opción B — Spark / PySpark
Recomendada como siguiente incremento.

Ventajas:
- mejor control de transformaciones
- prepara el terreno para escalabilidad real
- más alineada con el enunciado completo del taller

### Recomendación práctica
En este repositorio, usar **Athena CTAS como MVP ejecutable** y dejar **Spark como evolución documentada** o como fase adicional.

---

## 6. Particionamiento recomendado

### Raw
Por `ingest_date`

### Curated
Por `event_date`

### Justificación
- filtra naturalmente por fechas de negocio
- reduce costo y tiempo de consulta en Athena
- simplifica estrategias de backfill

---

## 7. Transformaciones concretas

## 7.1 pedidos
- validar fechas
- normalizar `estado`
- estandarizar tipos numéricos de `monto`

## 7.2 entregas
- convertir timestamps
- calcular `minutos_retraso`
- derivar `indicador_entrega_a_tiempo`

## 7.3 sensores
- normalizar timestamp
- validar rango de temperatura si se agrega regla
- separar eventos `TEMP_CRITICA`

## 7.4 dataset unificado
Join sugerido:
- `pedidos.id_cliente = clientes.id_cliente`
- `pedidos.id_producto = catalogo.id_producto`
- `pedidos.id_pedido = entregas.id_pedido`
- `entregas.vehiculo = sensores.vehiculo` cuando se requiera análisis agregado por vehículo

---

## 8. KPIs recomendados

### Operación logística
- `% entregas a tiempo`
- `retraso promedio por zona`
- `pedidos por tipo de cliente`
- `monto por categoría`
- `% cancelaciones`

### Monitoreo de transporte
- `número de TEMP_CRITICA por vehículo`
- `número de TEMP_CRITICA por zona`
- `vehículos con más alertas`
- `temperatura promedio por día`

---

## 9. Entradas y salidas

### Entradas
- tablas raw catalogadas
- reglas de negocio mínimas
- outputs de ingesta
- contratos y evidencia de validación

### Salidas
- tablas curated en S3
- vistas analíticas en Athena
- queries reutilizables
- base para QuickSight

---

## 10. SQL y artefactos que deben existir

- `sql/athena/02_ctas_pedidos_curated.sql`
- `sql/athena/03_ctas_sensores_curated.sql`
- `sql/athena/04_ctas_dimensiones.sql`
- `sql/athena/05_view_pedidos_unificados.sql`
- `sql/athena/06_insights.sql`

Cada archivo debe tener:
- objetivo del dataset
- query reproducible
- particionado esperado
- breve criterio de negocio

---

## 11. Errores comunes

### Error 1: curar directamente sobre CSV local sin dejar raw en S3
Consecuencia: la arquitectura queda incompleta y difícil de defender.

### Error 2: usar nombres ambiguos en tablas curated
Consecuencia: el modelo se vuelve difícil de explicar.

### Error 3: no separar dataset operacional de dataset analítico
Consecuencia: mezclar detalle técnico con consumo ejecutivo.

### Error 4: no derivar métricas de negocio
Consecuencia: la capa curated no demuestra valor.

### Error 5: ignorar particiones
Consecuencia: consultas más costosas y lentas.

---

## 12. Criterio de cierre de la fase

La fase se considera cerrada cuando:

- existen tablas curated en formato analítico
- se puede consultar un dataset unificado de pedidos
- se calculan al menos tres KPIs
- Athena responde consultas sobre curated
- hay evidencia de SQL ejecutado y resultados obtenidos

---

## 13. Checklist rápido

- [ ] pedidos_curated creado
- [ ] sensores_curated creado
- [ ] dataset unificado creado
- [ ] KPIs definidos
- [ ] particiones aplicadas
- [ ] consultas Athena ejecutadas
- [ ] evidencia guardada
- [ ] base lista para dashboard
