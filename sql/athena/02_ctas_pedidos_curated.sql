DROP TABLE IF EXISTS logidata_curated.pedidos_curated;

CREATE TABLE logidata_curated.pedidos_curated
WITH (
    format = 'PARQUET',
    external_location = 's3://<curated-bucket>/pedidos_curated/',
    parquet_compression = 'SNAPPY'
) AS
WITH base AS (
    SELECT
        p.id_pedido,
        p.id_cliente,
        p.id_producto,
        CAST(date_parse(p.fecha, '%Y-%m-%d %H:%i:%s') AS timestamp) AS fecha_pedido_ts,
        CAST(p.monto AS double) AS monto,
        p.estado,
        e.hora_programada,
        e.hora_real,
        e.zona AS zona_entrega,
        e.conductor,
        e.vehiculo,
        c.nombre AS nombre_cliente,
        c.zona AS zona_cliente,
        c.tipo_cliente,
        cat.categoria,
        CAST(cat.precio AS double) AS precio_catalogo,
        cat.tipo_entrega
    FROM logidata_raw.pedidos p
    LEFT JOIN logidata_raw.entregas e
        ON p.id_pedido = e.id_pedido
    LEFT JOIN logidata_raw.clientes c
        ON p.id_cliente = c.id_cliente
    LEFT JOIN logidata_raw.catalogo cat
        ON p.id_producto = cat.id_producto
),
typed AS (
    SELECT
        id_pedido,
        id_cliente,
        id_producto,
        fecha_pedido_ts,
        CAST(date(fecha_pedido_ts) AS date) AS fecha_pedido,
        year(fecha_pedido_ts) AS anio_pedido,
        month(fecha_pedido_ts) AS mes_pedido,
        date_format(fecha_pedido_ts, '%Y-%m') AS periodo_ym,
        monto,
        estado,
        CAST(date_parse(hora_programada, '%Y-%m-%d %H:%i:%s') AS timestamp) AS hora_programada_ts,
        CAST(date_parse(hora_real, '%Y-%m-%d %H:%i:%s') AS timestamp) AS hora_real_ts,
        zona_entrega,
        conductor,
        vehiculo,
        nombre_cliente,
        zona_cliente,
        tipo_cliente,
        categoria,
        precio_catalogo,
        tipo_entrega
    FROM base
)
SELECT
    id_pedido,
    id_cliente,
    id_producto,
    fecha_pedido_ts,
    fecha_pedido,
    anio_pedido,
    mes_pedido,
    periodo_ym,
    monto,
    estado,
    hora_programada_ts,
    hora_real_ts,
    CASE
        WHEN hora_programada_ts IS NOT NULL AND hora_real_ts IS NOT NULL
            THEN date_diff('minute', hora_programada_ts, hora_real_ts)
        ELSE NULL
    END AS minutos_desviacion_entrega,
    CASE
        WHEN hora_programada_ts IS NOT NULL
         AND hora_real_ts IS NOT NULL
         AND hora_real_ts <= hora_programada_ts THEN 1
        WHEN hora_programada_ts IS NOT NULL
         AND hora_real_ts IS NOT NULL THEN 0
        ELSE NULL
    END AS entrega_a_tiempo_flag,
    CASE
        WHEN estado = 'CANCELADO' THEN 1 ELSE 0
    END AS cancelado_flag,
    zona_entrega,
    conductor,
    vehiculo,
    nombre_cliente,
    zona_cliente,
    tipo_cliente,
    categoria,
    precio_catalogo,
    tipo_entrega
FROM typed;