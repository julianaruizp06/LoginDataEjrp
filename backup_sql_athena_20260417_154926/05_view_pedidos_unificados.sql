-- 05_view_pedidos_unificados.sql
-- Objetivo:
-- Exponer una vista unificada lista para exploración analítica y dashboard.
--
-- NOTA:
-- Este script asume tablas raw y curated con nombres simples.
-- Si en AWS/Athena los nombres finales cambian, ajustar referencias.
-- Vista estándar recomendada: vw_pedidos_unificados

CREATE OR REPLACE VIEW logidata_curated.vw_pedidos_unificados AS
SELECT
    p.id_pedido,
    p.fecha_pedido_ts,
    p.fecha_pedido,
    p.anio_pedido,
    p.mes_pedido,
    p.periodo_ym,
    p.id_cliente,
    dc.nombre_cliente,
    dc.zona_cliente,
    dc.tipo_cliente,
    p.id_producto,
    dp.categoria,
    dp.precio_catalogo,
    dp.tipo_entrega,
    p.estado,
    p.cancelado_flag,
    p.monto,
    p.hora_programada_ts,
    p.hora_real_ts,
    p.minutos_desviacion_entrega,
    p.entrega_a_tiempo_flag,
    p.vehiculo,
    dv.conductor,
    dv.zona_operacion
FROM logidata_curated.pedidos_curated p
LEFT JOIN logidata_curated.dim_cliente dc
    ON p.id_cliente = dc.id_cliente
LEFT JOIN logidata_curated.dim_producto dp
    ON p.id_producto = dp.id_producto
LEFT JOIN logidata_curated.dim_vehiculo dv
    ON p.vehiculo = dv.vehiculo;