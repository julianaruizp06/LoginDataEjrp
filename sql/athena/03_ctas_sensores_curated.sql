-- 03_ctas_sensores_curated.sql
-- Objetivo:
-- Curar eventos IoT de sensores para análisis en Athena y QuickSight.
--
-- IMPORTANTE:
-- 1) Reemplaza <curated-bucket> por el bucket real de curados antes de ejecutar.
-- 2) Este script asume que la tabla raw se llama logidata_raw.sensores.
--    Si Glue la crea con prefijo raw_local_, ajustar a:
--    logidata_raw.raw_local_sensores

DROP TABLE IF EXISTS logidata_curated.sensores_curated;

CREATE TABLE logidata_curated.sensores_curated
WITH (
    format = 'PARQUET',
    external_location = 's3://<curated-bucket>/sensores_curated/',
    parquet_compression = 'SNAPPY'
) AS
SELECT
    s.vehiculo,
    CAST(date_parse(s.timestamp, '%Y-%m-%d %H:%i:%s') AS timestamp) AS sensor_ts,
    CAST(date(CAST(date_parse(s.timestamp, '%Y-%m-%d %H:%i:%s') AS timestamp)) AS date) AS event_date,
    year(CAST(date_parse(s.timestamp, '%Y-%m-%d %H:%i:%s') AS timestamp)) AS event_year,
    month(CAST(date_parse(s.timestamp, '%Y-%m-%d %H:%i:%s') AS timestamp)) AS event_month,
    date_format(CAST(date_parse(s.timestamp, '%Y-%m-%d %H:%i:%s') AS timestamp), '%Y-%m') AS periodo_ym,
    CAST(s.latitud AS double) AS latitud,
    CAST(s.longitud AS double) AS longitud,
    CAST(s.temperatura AS double) AS temperatura,
    s.evento,
    CASE
        WHEN s.evento = 'TEMP_CRITICA' THEN 1
        ELSE 0
    END AS temp_critica_flag,
    CASE
        WHEN CAST(s.temperatura AS double) >= 8 THEN 'ALTA'
        WHEN CAST(s.temperatura AS double) >= 4 THEN 'MEDIA'
        ELSE 'BAJA'
    END AS severidad_temperatura
FROM logidata_raw.sensores s
WHERE s.vehiculo IS NOT NULL
  AND s.timestamp IS NOT NULL;