# 09. Dashboard & QuickSight

## Objetivo de esta capa

Construir un dashboard funcional orientado a operación logística y monitoreo ejecutivo, usando QuickSight sobre la capa curated del proyecto.

---

## 1. Fuente de datos recomendada

### Dataset principal
`logidata_curated.vw_pedidos_unificados`

### Dataset complementario
`logidata_curated.sensores_curated`

### Justificación
- la vista unificada reduce complejidad en QuickSight,
- concentra atributos de cliente, producto, entrega y vehículo,
- el dataset de sensores permite análisis específico de alertas.

---

## 2. Métricas mínimas del dashboard

### KPIs obligatorios
1. **Total pedidos**
2. **Monto total**
3. **% cancelación**
4. **% entrega a tiempo**
5. **Total alertas TEMP_CRITICA**

### KPIs opcionales
- ticket promedio,
- retraso promedio,
- top vehículos con alertas,
- top zonas por monto.

---

## 3. Visuales recomendados

### Visual 1: KPI cards
Mostrar:
- total pedidos,
- monto total,
- % cancelación,
- % entrega a tiempo.

### Visual 2: barras por zona y tipo de cliente
Objetivo:
- comparar volumen o monto por `zona_cliente` y `tipo_cliente`.

### Visual 3: línea temporal
Objetivo:
- ver evolución de pedidos o alertas por día.

### Visual 4: barras de alertas por vehículo
Objetivo:
- identificar flota crítica.

### Visual 5: tabla operacional
Objetivo:
- mostrar detalle con:
  - pedido,
  - fecha,
  - cliente,
  - zona,
  - tipo_entrega,
  - estado,
  - vehículo,
  - minutos_desviacion_entrega.

---

## 4. Filtros recomendados

Filtros mínimos:
- fecha,
- zona_cliente,
- tipo_cliente,
- tipo_entrega,
- estado,
- vehiculo.

Estos filtros le dan valor real al dashboard y permiten navegación en demo.

---

## 5. Campos calculados sugeridos

### `% cancelación`
Si no se calcula en SQL, puede calcularse en QuickSight a partir de `cancelado_flag`.

### `% entrega a tiempo`
Basado en `entrega_a_tiempo_flag`.

### `alertas críticas`
Basado en `temp_critica_flag`.

### `periodo_ym`
Útil para agrupación mensual rápida.

---

## 6. Historia que debe contar el dashboard

La demo del dashboard debe responder en menos de 2 minutos:
- cuántos pedidos se procesaron,
- cuánto dinero se movió,
- qué tan bien se entregó,
- dónde están los mayores problemas,
- qué vehículos presentan riesgo térmico.

---

## 7. Secuencia recomendada para la demo

1. Abrir dashboard con KPIs globales.
2. Filtrar por zona.
3. Mostrar desempeño por tipo de cliente.
4. Cambiar al panel de alertas de sensores.
5. Mostrar top vehículos con `TEMP_CRITICA`.
6. Concluir con una lectura ejecutiva.

---

## 8. Buenas prácticas para QuickSight

- evitar exceso de gráficos,
- usar nombres claros,
- dejar filtros arriba,
- no mezclar demasiados colores o ejes,
- priorizar KPI + tendencia + detalle.

---

## 9. Qué evidencia guardar

- screenshot del dataset cargado,
- screenshot del dashboard final,
- screenshot de filtros en acción,
- screenshot de una consulta Athena que alimente el dashboard.

Guardar todo eso en `evidence/screenshots/`.

---

## 10. Estado esperado del repo

Idealmente deberían existir:
- `quicksight/datasets.md`
- `quicksight/dashboard_spec.md`
- capturas del dashboard,
- este documento explicando la lógica y los visuales.
