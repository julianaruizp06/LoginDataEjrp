-- 01_raw_sanity_checks.sql
-- Objetivo:
-- Ejecutar validaciones básicas sobre la capa raw antes de construir la capa curated.

-- Si Glue crea tablas con prefijo raw_local_, ajustar nombres antes de ejecutar.


-- 1) Conteo de registros por tabla raw

SELECT COUNT(*) AS total_clientes
FROM logidata_raw.clientes;

SELECT COUNT(*) AS total_catalogo
FROM logidata_raw.catalogo;

SELECT COUNT(*) AS total_pedidos
FROM logidata_raw.pedidos;

SELECT COUNT(*) AS total_entregas
FROM logidata_raw.entregas;

SELECT COUNT(*) AS total_sensores
FROM logidata_raw.sensores;


-- 2) Validación de dominios en pedidos.estado

SELECT
    estado,
    COUNT(*) AS total
FROM logidata_raw.pedidos
GROUP BY estado
ORDER BY total DESC;


-- 3) Validación de dominios en sensores.evento

SELECT
    evento,
    COUNT(*) AS total
FROM logidata_raw.sensores
GROUP BY evento
ORDER BY total DESC;

-- 4) Muestra de registros de pedidos

SELECT *
FROM logidata_raw.pedidos
LIMIT 10;


-- 5) Muestra de registros de sensores

SELECT *
FROM logidata_raw.sensores
LIMIT 10;


-- 6) Nulos en claves relevantes de pedidos

SELECT
    SUM(CASE WHEN id_pedido IS NULL THEN 1 ELSE 0 END) AS null_id_pedido,
    SUM(CASE WHEN id_cliente IS NULL THEN 1 ELSE 0 END) AS null_id_cliente,
    SUM(CASE WHEN id_producto IS NULL THEN 1 ELSE 0 END) AS null_id_producto,
    SUM(CASE WHEN fecha IS NULL THEN 1 ELSE 0 END) AS null_fecha,
    SUM(CASE WHEN estado IS NULL THEN 1 ELSE 0 END) AS null_estado
FROM logidata_raw.pedidos;


-- 7) Nulos en claves relevantes de sensores

SELECT
    SUM(CASE WHEN vehiculo IS NULL THEN 1 ELSE 0 END) AS null_vehiculo,
    SUM(CASE WHEN timestamp IS NULL THEN 1 ELSE 0 END) AS null_timestamp,
    SUM(CASE WHEN temperatura IS NULL THEN 1 ELSE 0 END) AS null_temperatura,
    SUM(CASE WHEN evento IS NULL THEN 1 ELSE 0 END) AS null_evento
FROM logidata_raw.sensores;


-- 8) Duplicados potenciales en pedidos

SELECT
    id_pedido,
    COUNT(*) AS repeticiones
FROM logidata_raw.pedidos
GROUP BY id_pedido
HAVING COUNT(*) > 1
ORDER BY repeticiones DESC, id_pedido;


-- 9) Duplicados potenciales en sensores por vehiculo + timestamp

SELECT
    vehiculo,
    timestamp,
    COUNT(*) AS repeticiones
FROM logidata_raw.sensores
GROUP BY vehiculo, timestamp
HAVING COUNT(*) > 1
ORDER BY repeticiones DESC, vehiculo, timestamp;