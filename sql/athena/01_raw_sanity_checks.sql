-- 01_raw_sanity_checks.sql
-- Validaciones básicas de la capa raw.
-- Si Glue creó tablas con prefijo, por ejemplo raw_local_pedidos,
-- reemplaza los nombres en este archivo antes de ejecutar.

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

SELECT estado, COUNT(*) AS total
FROM logidata_raw.pedidos
GROUP BY estado
ORDER BY total DESC;

SELECT evento, COUNT(*) AS total
FROM logidata_raw.sensores
GROUP BY evento
ORDER BY total DESC;

SELECT *
FROM logidata_raw.pedidos
LIMIT 10;

SELECT *
FROM logidata_raw.sensores
LIMIT 10;-- 01_raw_sanity_checks.sql
-- Validaciones básicas de la capa raw.
-- Si Glue creó tablas con prefijo, por ejemplo raw_local_pedidos,
-- reemplaza los nombres en este archivo antes de ejecutar.

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

SELECT estado, COUNT(*) AS total
FROM logidata_raw.pedidos
GROUP BY estado
ORDER BY total DESC;

SELECT evento, COUNT(*) AS total
FROM logidata_raw.sensores
GROUP BY evento
ORDER BY total DESC;

SELECT *
FROM logidata_raw.pedidos
LIMIT 10;

SELECT *
FROM logidata_raw.sensores
LIMIT 10;-- 01_raw_sanity_checks.sql
-- Validaciones básicas de la capa raw.
-- Si Glue creó tablas con prefijo, por ejemplo raw_local_pedidos,
-- reemplaza los nombres en este archivo antes de ejecutar.

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

SELECT estado, COUNT(*) AS total
FROM logidata_raw.pedidos
GROUP BY estado
ORDER BY total DESC;

SELECT evento, COUNT(*) AS total
FROM logidata_raw.sensores
GROUP BY evento
ORDER BY total DESC;

SELECT *
FROM logidata_raw.pedidos
LIMIT 10;

SELECT *
FROM logidata_raw.sensores
LIMIT 10;