-- 04_ctas_dimensiones.sql
-- Objetivo:
-- Crear dimensiones analíticas mínimas para consumo en Athena y QuickSight.
--
-- DIMENSIÓN CLIENTE
DROP TABLE IF EXISTS logidata_curated.dim_cliente;

CREATE TABLE logidata_curated.dim_cliente
WITH (
    format = 'PARQUET',
    external_location = 's3://ejrp-g01-curated-ejrp/curated/dim_cliente/',
    parquet_compression = 'SNAPPY'
) AS
SELECT DISTINCT
    c.id_cliente,
    c.nombre AS nombre_cliente,
    c.zona AS zona_cliente,
    c.tipo_cliente
FROM logidata_raw.raw_local_clientes c
WHERE c.id_cliente IS NOT NULL;


-- DIMENSIÓN PRODUCTO
DROP TABLE IF EXISTS logidata_curated.dim_producto;

CREATE TABLE logidata_curated.dim_producto
WITH (
    format = 'PARQUET',
    external_location = 's3://ejrp-g01-curated-ejrp/curated/dim_producto/',
    parquet_compression = 'SNAPPY'
) AS
SELECT DISTINCT
    cat.id_producto,
    cat.categoria,
    CAST(cat.precio AS double) AS precio_catalogo,
    cat.tipo_entrega
FROM logidata_raw.raw_local_catalogo cat
WHERE cat.id_producto IS NOT NULL;


-- DIMENSIÓN VEHÍCULO
DROP TABLE IF EXISTS logidata_curated.dim_vehiculo;

CREATE TABLE logidata_curated.dim_vehiculo
WITH (
    format = 'PARQUET',
    external_location = 's3://ejrp-g01-curated-ejrp/curated/dim_vehiculo/',
    parquet_compression = 'SNAPPY'
) AS
SELECT DISTINCT
    e.vehiculo,
    e.conductor,
    e.zona AS zona_operacion
FROM logidata_raw.raw_local_entregas e
WHERE e.vehiculo IS NOT NULL;

-- DIMENSIÓN FECHA
DROP TABLE IF EXISTS logidata_curated.dim_fecha;

CREATE TABLE logidata_curated.dim_fecha
WITH (
    format = 'PARQUET',
    external_location = 's3://ejrp-g01-curated-ejrp/curated/dim_fecha/',
    parquet_compression = 'SNAPPY'
) AS
SELECT DISTINCT
    p.fecha_pedido AS fecha,
    year(CAST(p.fecha_pedido AS timestamp)) AS anio,
    month(CAST(p.fecha_pedido AS timestamp)) AS mes,
    day(CAST(p.fecha_pedido AS timestamp)) AS dia,
    week(CAST(p.fecha_pedido AS timestamp)) AS semana_anio,
    quarter(CAST(p.fecha_pedido AS timestamp)) AS trimestre,
    date_format(CAST(p.fecha_pedido AS timestamp), '%Y-%m') AS periodo_ym
FROM logidata_curated.pedidos_curated p
WHERE p.fecha_pedido IS NOT NULL;