# Queries en Athena

## Configuración previa

Verificar lo siguiente en Athena:

- **Workgroup:** `ejrp-g01-dev-wg`
- **Data source:** `AwsDataCatalog`
- **Database:** `logidata_curated`

---

## 1. Validación técnica de la capa curated

### 1.1 Total de registros en capa curated

total de res¿gsitros eb cada tabla

```sql
SELECT 'pedidos_curated' AS tabla, COUNT(*) AS total FROM logidata_curated.pedidos_curated
UNION ALL
SELECT 'sensores_curated' AS tabla, COUNT(*) AS total FROM logidata_curated.sensores_curated
UNION ALL
SELECT 'dim_cliente' AS tabla, COUNT(*) AS total FROM logidata_curated.dim_cliente
UNION ALL
SELECT 'vw_pedidos_unificados' AS tabla, COUNT(*) AS total FROM logidata_curated.vw_pedidos_unificados;


1.2 Revisión rápida de datos

Muestra de pedidos_curated
SQL
SELECT *
FROM logidata_curated.pedidos_curated
LIMIT 20;
-----------------------------------
Muestra de sensores_curated
SQL
SELECT *
FROM logidata_curated.sensores_curated
LIMIT 20;
-----------------------
Muestra de vw_pedidos_unificados
SQL
SELECT *
FROM logidata_curated.vw_pedidos_unificados
LIMIT 20;

###3. Validación técnica de la capa curated
3.1 KPI general del negocio
SELECT
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    SUM(monto) AS monto_total,
    AVG(monto) AS ticket_promedio,
    SUM(cancelado_flag) AS pedidos_cancelados,
    100.0 * SUM(cancelado_flag) / COUNT(DISTINCT id_pedido) AS pct_cancelacion,
    100.0 * AVG(CAST(entrega_a_tiempo_flag AS double)) AS pct_entrega_a_tiempo
FROM logidata_curated.vw_pedidos_unificados;
-------------------------

3.2 Desempeño por zona y tipo de cliente
SELECT
    zona_cliente,
    tipo_cliente,
    COUNT(DISTINCT id_pedido) AS pedidos,
    SUM(monto) AS monto_total,
    100.0 * AVG(CAST(entrega_a_tiempo_flag AS double)) AS pct_entrega_a_tiempo,
    100.0 * AVG(CAST(cancelado_flag AS double)) AS pct_cancelacion
FROM logidata_curated.vw_pedidos_unificados
GROUP BY 1, 2
ORDER BY monto_total DESC;
---------------------------------

3.3 Retraso promedio por tipo de entrega
SELECT
    tipo_entrega,
    COUNT(DISTINCT id_pedido) AS pedidos,
    AVG(minutos_desviacion_entrega) AS promedio_minutos_desviacion,
    MAX(minutos_desviacion_entrega) AS max_minutos_desviacion
FROM logidata_curated.vw_pedidos_unificados
WHERE minutos_desviacion_entrega IS NOT NULL
GROUP BY 1
ORDER BY promedio_minutos_desviacion DESC;
-------------------------------------------

3.4 Vehículos con más alertas críticas
SELECT
    vehiculo,
    COUNT(*) AS eventos_criticos,
    AVG(temperatura) AS temperatura_promedio_critica,
    MAX(temperatura) AS temperatura_maxima
FROM logidata_curated.sensores_curated
WHERE temp_critica_flag = 1
GROUP BY 1
ORDER BY eventos_criticos DESC, temperatura_maxima DESC
LIMIT 20;
3.5 Alertas por día
SELECT
    event_date,
    COUNT(*) AS total_eventos,
    SUM(temp_critica_flag) AS alertas_temp_critica,
    100.0 * SUM(temp_critica_flag) / COUNT(*) AS pct_alertas
FROM logidata_curated.sensores_curated
GROUP BY 1
ORDER BY 1;
------------------------------------------------------

3.6 Cruce operativo: pedidos por vehículo vs alertas
SELECT
    p.vehiculo,
    COUNT(DISTINCT p.id_pedido) AS pedidos_asociados,
    SUM(CASE WHEN p.estado = 'ENTREGADO' THEN 1 ELSE 0 END) AS pedidos_entregados,
    COALESCE(s.alertas_temp_critica, 0) AS alertas_temp_critica
FROM logidata_curated.vw_pedidos_unificados p
LEFT JOIN (
    SELECT
        vehiculo,
        SUM(temp_critica_flag) AS alertas_temp_critica
    FROM logidata_curated.sensores_curated
    GROUP BY 1
) s
    ON p.vehiculo = s.vehiculo
GROUP BY 1, 4
ORDER BY alertas_temp_critica DESC, pedidos_asociados DESC;
--------------------------------------------------------------

4. Query resumen final para validación rápida
SELECT 'pedidos_curated' AS tabla, COUNT(*) AS total FROM logidata_curated.pedidos_curated
UNION ALL
SELECT 'sensores_curated' AS tabla, COUNT(*) AS total FROM logidata_curated.sensores_curated
UNION ALL
SELECT 'dim_cliente' AS tabla, COUNT(*) AS total FROM logidata_curated.dim_cliente
UNION ALL
SELECT 'dim_producto' AS tabla, COUNT(*) AS total FROM logidata_curated.dim_producto
UNION ALL
SELECT 'dim_vehiculo' AS tabla, COUNT(*) AS total FROM logidata_curated.dim_vehiculo
UNION ALL
SELECT 'dim_fecha' AS tabla, COUNT(*) AS total FROM logidata_curated.dim_fecha
UNION ALL
SELECT 'vw_pedidos_unificados' AS tabla, COUNT(*) AS total FROM logidata_curated.vw_pedidos_unificados;
----------------------------------------------------------------------------------------------------------------------
1. Ventas y operación
1.1 Top zonas con mayor facturación
Qué muestra: qué zonas concentran más ingresos.
Para qué sirve: ayuda a identificar mercados más rentables.

SELECT
    zona_cliente,
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    SUM(monto) AS monto_total
FROM logidata_curated.vw_pedidos_unificados
GROUP BY 1
ORDER BY monto_total DESC;
-----------------------------------------------------

 1.2 Ventas por mes
 Qué muestra: evoución mensual del monto total y número de pedidos.  
Para qué sirve: permite ver tendencia comercial y estacionalidad.
SELECT
    periodo_ym,
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    SUM(monto) AS monto_total,
    AVG(monto) AS ticket_promedio
FROM logidata_curated.vw_pedidos_unificados
GROUP BY 1
ORDER BY 1;
------------------------

1.3 Top clientes por monto
Qué muestra: clientes con mayor volumen de compra.
Para qué sirve: sirve para identificar cuentas clave.

SELECT
    nombre_cliente,
    tipo_cliente,
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    SUM(monto) AS monto_total,
    AVG(monto) AS ticket_promedio
FROM logidata_curated.vw_pedidos_unificados
GROUP BY 1, 2
ORDER BY monto_total DESC
LIMIT 20;
-----------------------------------------

2. Cumplimiento logístico
2.1 Porcentaje de entregas a tiempo por zona

Qué muestra: nivel de cumplimiento operativo por zona geográfica.
Para qué sirve: ayuda a detectar problemas logísticos regionales.

SELECT
    zona_entrega,
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    100.0 * AVG(CAST(entrega_a_tiempo_flag AS double)) AS pct_entrega_a_tiempo,
    AVG(minutos_desviacion_entrega) AS promedio_desviacion_min
FROM logidata_curated.vw_pedidos_unificados
GROUP BY 1
ORDER BY pct_entrega_a_tiempo ASC, promedio_desviacion_min DESC;
2.2 Conductores con más retrasos promedio

Qué muestra: conductores con peor desempeño en tiempos de entrega.
Para qué sirve: útil para seguimiento operativo y mejora de desempeño.

SELECT
    conductor,
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    AVG(minutos_desviacion_entrega) AS promedio_desviacion_min,
    MAX(minutos_desviacion_entrega) AS max_desviacion_min
FROM logidata_curated.vw_pedidos_unificados
WHERE minutos_desviacion_entrega IS NOT NULL
GROUP BY 1
ORDER BY promedio_desviacion_min DESC
LIMIT 20;
2.3 Vehículos con peor cumplimiento de entregas

Qué muestra: vehículos asociados a menor porcentaje de entregas a tiempo.
Para qué sirve: ayuda a cruzar desempeño logístico con posibles problemas de flota.

SELECT
    vehiculo,
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    100.0 * AVG(CAST(entrega_a_tiempo_flag AS double)) AS pct_entrega_a_tiempo,
    AVG(minutos_desviacion_entrega) AS promedio_desviacion_min
FROM logidata_curated.vw_pedidos_unificados
GROUP BY 1
ORDER BY pct_entrega_a_tiempo ASC, promedio_desviacion_min DESC
LIMIT 20;
3. Cancelaciones y riesgo operativo
3.1 Cancelación por tipo de cliente

Qué muestra: qué tipo de cliente cancela más pedidos.
Para qué sirve: ayuda a detectar segmentos con mayor riesgo comercial.

SELECT
    tipo_cliente,
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    SUM(cancelado_flag) AS pedidos_cancelados,
    100.0 * AVG(CAST(cancelado_flag AS double)) AS pct_cancelacion
FROM logidata_curated.vw_pedidos_unificados
GROUP BY 1
ORDER BY pct_cancelacion DESC;
3.2 Cancelación por categoría de producto

Qué muestra: categorías con mayor porcentaje de cancelación.
Para qué sirve: útil para detectar productos problemáticos o con fricción operativa.

SELECT
    categoria,
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    SUM(cancelado_flag) AS pedidos_cancelados,
    100.0 * AVG(CAST(cancelado_flag AS double)) AS pct_cancelacion
FROM logidata_curated.vw_pedidos_unificados
GROUP BY 1
ORDER BY pct_cancelacion DESC;
3.3 Zonas con más cancelaciones

Qué muestra: distribución territorial de cancelaciones.
Para qué sirve: ayuda a detectar zonas de mayor complejidad logística o menor calidad de servicio.

SELECT
    zona_cliente,
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    SUM(cancelado_flag) AS pedidos_cancelados,
    100.0 * AVG(CAST(cancelado_flag AS double)) AS pct_cancelacion
FROM logidata_curated.vw_pedidos_unificados
GROUP BY 1
ORDER BY pct_cancelacion DESC;
4. Sensores y cadena de frío
4.1 Temperatura promedio por vehículo

Qué muestra: comportamiento térmico promedio de cada vehículo.
Para qué sirve: ayuda a evaluar estabilidad de la cadena de frío.

SELECT
    vehiculo,
    COUNT(*) AS total_eventos,
    AVG(temperatura) AS temperatura_promedio,
    MAX(temperatura) AS temperatura_maxima,
    MIN(temperatura) AS temperatura_minima
FROM logidata_curated.sensores_curated
GROUP BY 1
ORDER BY temperatura_promedio DESC;
4.2 Vehículos con más eventos de temperatura crítica

Qué muestra: qué vehículos tuvieron más incidentes críticos.
Para qué sirve: prioriza inspección o mantenimiento de flota.

SELECT
    vehiculo,
    SUM(temp_critica_flag) AS alertas_criticas,
    COUNT(*) AS total_eventos,
    100.0 * SUM(temp_critica_flag) / COUNT(*) AS pct_eventos_criticos
FROM logidata_curated.sensores_curated
GROUP BY 1
ORDER BY alertas_criticas DESC, pct_eventos_criticos DESC;
4.3 Distribución de severidad de temperatura

Qué muestra: cantidad de eventos en cada nivel de severidad.
Para qué sirve: da una vista rápida del riesgo total monitoreado.

SELECT
    severidad_temperatura,
    COUNT(*) AS total_eventos
FROM logidata_curated.sensores_curated
GROUP BY 1
ORDER BY total_eventos DESC;
5. Cruces entre ventas y operación
5.1 Monto total por vehículo

Qué muestra: cuánto negocio movió cada vehículo.
Para qué sirve: permite comparar impacto económico por unidad operativa.

SELECT
    vehiculo,
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    SUM(monto) AS monto_total,
    AVG(monto) AS ticket_promedio
FROM logidata_curated.vw_pedidos_unificados
GROUP BY 1
ORDER BY monto_total DESC;
5.2 Vehículos con más monto y más alertas

Qué muestra: cruza valor económico transportado con alertas críticas.
Para qué sirve: identifica vehículos de alto impacto y alto riesgo.

SELECT
    p.vehiculo,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    SUM(p.monto) AS monto_total,
    COALESCE(s.alertas_temp_critica, 0) AS alertas_temp_critica
FROM logidata_curated.vw_pedidos_unificados p
LEFT JOIN (
    SELECT
        vehiculo,
        SUM(temp_critica_flag) AS alertas_temp_critica
    FROM logidata_curated.sensores_curated
    GROUP BY 1
) s
    ON p.vehiculo = s.vehiculo
GROUP BY 1, 4
ORDER BY monto_total DESC, alertas_temp_critica DESC;
------------------------------------------------------

5.3 Relación entre alertas y cumplimiento

Qué muestra: comparación entre alertas críticas y entregas a tiempo por vehículo.
Para qué sirve: permite ver si incidentes térmicos están asociados a peor desempeño logístico.

SELECT
    p.vehiculo,
    COUNT(DISTINCT p.id_pedido) AS total_pedidos,
    100.0 * AVG(CAST(p.entrega_a_tiempo_flag AS double)) AS pct_entrega_a_tiempo,
    COALESCE(s.alertas_temp_critica, 0) AS alertas_temp_critica
FROM logidata_curated.vw_pedidos_unificados p
LEFT JOIN (
    SELECT
        vehiculo,
        SUM(temp_critica_flag) AS alertas_temp_critica
    FROM logidata_curated.sensores_curated
    GROUP BY 1
) s
    ON p.vehiculo = s.vehiculo
GROUP BY 1, 4
ORDER BY alertas_temp_critica DESC, pct_entrega_a_tiempo ASC;