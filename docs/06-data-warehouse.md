# 06. Data Warehouse

## Objetivo de esta capa

Diseñar una bodega de datos simple pero defendible, enfocada en indicadores operativos y logísticos para LogiData S.A.S.

La meta no es construir un modelo enterprise gigantesco, sino una estructura clara que permita responder preguntas de negocio como:

- ¿qué porcentaje de pedidos se entrega a tiempo?
- ¿qué zonas presentan más retrasos?
- ¿qué tipo de cliente genera más ingresos?
- ¿qué vehículos concentran más alertas de temperatura?

---

## 1. Grano de la bodega

### Hecho principal recomendado
**Fact de pedidos / entregas** con grano:

> **1 fila por pedido**

Esto permite medir:
- monto,
- estado,
- entrega a tiempo,
- minutos de desviación,
- cliente,
- producto,
- vehículo asociado.

### Hecho secundario recomendado
**Fact de sensores** con grano:

> **1 fila por evento de sensor**

Esto permite medir:
- temperatura,
- alertas críticas,
- distribución temporal de eventos,
- comportamiento por vehículo.

---

## 2. Bus matrix

| Proceso de negocio | Dim Fecha | Dim Cliente | Dim Producto | Dim Vehículo | Medidas principales |
|---|---|---|---|---|---|
| Pedidos | Sí | Sí | Sí | Sí | monto, cancelado_flag, entrega_a_tiempo_flag, minutos_desviacion_entrega |
| Sensores | Sí | No | No | Sí | temperatura, temp_critica_flag |

Esta matriz es suficiente para explicar conformidad dimensional sin sobrediseñar el taller.

---

## 3. Dimensiones propuestas

### `dim_cliente`
Campos sugeridos:
- `id_cliente`
- `nombre_cliente`
- `zona_cliente`
- `tipo_cliente`

### `dim_producto`
Campos sugeridos:
- `id_producto`
- `categoria`
- `precio_catalogo`
- `tipo_entrega`

### `dim_vehiculo`
Campos sugeridos:
- `vehiculo`
- `conductor`
- `zona_operacion`

### `dim_fecha`
Campos sugeridos:
- `fecha`
- `anio`
- `mes`
- `dia`
- `semana_anio`
- `trimestre`
- `periodo_ym`

---

## 4. Hechos propuestos

### `fact_pedidos`
Campos sugeridos:
- `id_pedido`
- `id_cliente`
- `id_producto`
- `vehiculo`
- `fecha_pedido`
- `monto`
- `estado`
- `cancelado_flag`
- `entrega_a_tiempo_flag`
- `minutos_desviacion_entrega`

### `fact_sensores`
Campos sugeridos:
- `vehiculo`
- `sensor_ts`
- `event_date`
- `temperatura`
- `evento`
- `temp_critica_flag`
- `severidad_temperatura`

---

## 5. Medidas de negocio recomendadas

### KPIs mínimos
1. **Total pedidos**
2. **Monto total**
3. **Ticket promedio**
4. **% cancelación**
5. **% entrega a tiempo**
6. **Promedio de desviación de entrega**
7. **Total alertas TEMP_CRITICA**

### Fórmulas útiles
- `% cancelación = SUM(cancelado_flag) / COUNT(id_pedido)`
- `% entrega a tiempo = AVG(entrega_a_tiempo_flag)`
- `promedio retraso = AVG(minutos_desviacion_entrega)`

---

## 6. Estrategia SCD

Para este taller, la recomendación realista es:

- **SCD Tipo 1** para dimensiones simples como cliente, producto y vehículo.

### Justificación
- No hay evidencia en el caso de cambios históricos complejos de atributos.
- El foco del taller está más en integración y pipeline que en lenta evolución maestra.
- Es más simple de defender y de implementar con CTAS o Spark.

Si el panel pregunta:
> “¿Por qué no SCD Tipo 2?”

La respuesta defendible es:
> Porque el caso entregado no prioriza historia de atributos ni auditoría de cambios dimensionales; el valor principal está en pedidos, entregas y sensores recientes.

---

## 7. Implementación en este proyecto

En el repo actual, la bodega está representada de forma liviana usando:
- `logidata_curated.pedidos_curated`
- `logidata_curated.sensores_curated`
- `dim_cliente`
- `dim_producto`
- `dim_vehiculo`
- `dim_fecha`
- `vw_pedidos_unificados`

Esto funciona como un **mini data warehouse sobre Athena**, suficiente para QuickSight y sustentación.

---

## 8. Staging y capas

### Capa raw
- datos tal como llegan,
- validaciones mínimas,
- sin lógica de negocio fuerte.

### Capa curated
- cast de tipos,
- joins entre pedidos, entregas, clientes y catálogo,
- columnas derivadas,
- flags y métricas operativas.

### Capa analytics / consumo
- dimensiones,
- vista unificada,
- queries de insights,
- dashboard.

---

## 9. Qué mostrar en la sustentación

- bus matrix,
- grano del hecho principal y del hecho de sensores,
- dimensiones conformadas,
- KPIs y fórmulas,
- relación entre CTAS y dashboard final.

---

## 10. Estado esperado del repo

Para cerrar esta historia, el repositorio debe tener:
- SQL de curated,
- SQL de dimensiones,
- vista unificada,
- queries de insights,
- este documento con el racional de modelado.
