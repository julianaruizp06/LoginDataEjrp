-- 06_insights.sql
-- Objetivo:
-- Consultas de negocio para validación, demo y dashboard.
--
-- NOTA:
-- Este script asume que ya existen:
--   logidata_curated.vw_pedidos_unificados
--   logidata_curated.sensores_curated


-- 1) KPI general del negocio

SELECT
    COUNT(DISTINCT id_pedido) AS total_pedidos,
    SUM(monto) AS monto_total,
    AVG(monto) AS ticket_promedio,
    SUM(cancelado_flag) AS pedidos_cancelados,
    100.0 * SUM(cancelado_flag) / COUNT(DISTINCT id_pedido) AS pct_cancelacion,
    100.0 * AVG(CAST(entrega_a_tiempo_flag AS double)) AS pct_entrega_a_tiempo
FROM logidata_curated.vw_pedidos_unificados;


-- 2) Desempeño por zona y tipo de cliente

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


-- 3) Retraso promedio por tipo de entrega

SELECT
    tipo_entrega,
    COUNT(DISTINCT id_pedido) AS pedidos,
    AVG(minutos_desviacion_entrega) AS promedio_minutos_desviacion,
    MAX(minutos_desviacion_entrega) AS max_minutos_desviacion
FROM logidata_curated.vw_pedidos_unificados
WHERE minutos_desviacion_entrega IS NOT NULL
GROUP BY 1
ORDER BY promedio_minutos_desviacion DESC;


-- 4) Vehículos con más alertas críticas

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


-- 5) Alertas por día

SELECT
    event_date,
    COUNT(*) AS total_eventos,
    SUM(temp_critica_flag) AS alertas_temp_critica,
    100.0 * SUM(temp_critica_flag) / COUNT(*) AS pct_alertas
FROM logidata_curated.sensores_curated
GROUP BY 1
ORDER BY 1;


-- 6) Cruce operativo: pedidos por vehículo vs alertas

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