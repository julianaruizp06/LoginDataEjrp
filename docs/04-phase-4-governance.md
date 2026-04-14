# Fase 4 — Consumo y Gobierno

Esta fase convierte el repositorio en una solución defendible. No solo importa que los datos existan, sino que tengan trazabilidad, acceso controlado, monitoreo, evidencia y una historia técnica clara.

---

## 1. Objetivo

Formalizar controles y prácticas de gobierno para:

- hacer consumibles los datasets
- mantener trazabilidad operativa
- controlar acceso y exposición
- documentar evolución de esquema
- fortalecer observabilidad
- dejar material listo para sustentación

---

## 2. Catálogo y descubrimiento

## 2.1 Glue Data Catalog
Glue actúa como capa central de metadatos.

### Qué debe quedar visible
- bases de datos lógicas
- tablas raw
- tablas curated
- ubicación S3 por dataset
- esquema detectado o definido
- particiones si aplican

## 2.2 Buenas prácticas
- usar nombres consistentes por dominio
- evitar tablas temporales confusas
- documentar propósito de cada tabla en docs y evidencia
- separar raw y curated también en catálogo

---

## 3. Acceso y seguridad

## 3.1 IAM como control base
Para el alcance actual del repositorio, IAM es el mínimo obligatorio.

Debe controlar:
- acceso a buckets
- consulta Athena
- ejecución Glue
- publicación en Kinesis
- escritura por Firehose

## 3.2 Lake Formation
Puede mantenerse como evolución o placeholder documentado si aún no se implementa fino.

### Cuándo justificar su no implementación completa
- alcance académico
- tiempo limitado
- prioridad en dejar pipeline demostrable primero

### Qué sí debe quedar dicho
- Lake Formation sería la siguiente capa para permisos granulares por tabla, columna o dominio

---

## 4. Calidad y gobierno operativo

## 4.1 Contratos
Los contratos siguen siendo el primer control de calidad.

## 4.2 Quarantine
Debe existir trazabilidad de:
- qué falló
- cuándo falló
- en qué lote
- cuál era el registro original

## 4.3 Evolución de esquema
Se aplica la regla:

- agregar columnas: compatible
- cambiar tipo, remover o renombrar: nueva versión de contrato

## 4.4 Evidencia mínima
- muestras de registros quarantined
- logs por batch
- métricas por lote
- capturas del catálogo
- capturas de Athena

---

## 5. Observabilidad

## 5.1 Logs
Formato recomendado: JSONL

Campos mínimos:
- `ts_utc`
- `level`
- `component`
- `dataset`
- `batch_id`
- `message`

## 5.2 Métricas
Métricas mínimas por batch:
- `records_read`
- `records_valid`
- `records_quarantined`
- `duration_ms`
- `error_count`

## 5.3 Métricas útiles para sustentación
- porcentaje de válidos
- porcentaje de quarantine
- tiempo de procesamiento por lote
- número de tablas catalogadas
- número de eventos streaming aterrizados

---

## 6. Consumo analítico

Aunque el dashboard final puede ser una fase adicional, en esta fase debe quedar lista la base de consumo.

### Mínimo esperado
- datasets curated consultables
- queries de insights reutilizables
- salida preparada para QuickSight o demo SQL

### Consumos sugeridos
- análisis de cumplimiento logístico
- monitoreo de temperatura
- comparación por zona y tipo de cliente

---

## 7. CI/CD y gobernanza del repositorio

## 7.1 GitHub Actions
La CI debe validar, como mínimo:

- `pytest`
- `terraform fmt`
- `terraform validate`

## 7.2 Recomendaciones
- incluir la rama real de trabajo en los triggers
- fallar el pipeline si un test crítico falla
- evitar merge sin checks mínimos

## 7.3 Versionamiento
Todo cambio relevante debe versionarse:
- contratos
- SQL
- Terraform
- scripts
- documentación

---

## 8. Material de sustentación que nace en esta fase

- resumen ejecutivo del proyecto
- arquitectura final exportada
- evidencia de infraestructura desplegada
- evidencia de catálogo Glue
- evidencia de consultas Athena
- evidencia de quarantine y observabilidad
- guion técnico de demo

---

## 9. Riesgos y mitigaciones

### Riesgo: el catálogo detecta tipos incorrectos
Mitigación: fijar esquema explícito en tablas críticas curated.

### Riesgo: el dashboard se arma sobre raw
Mitigación: obligar el consumo desde curated o vistas analíticas.

### Riesgo: la rama principal no ejecuta CI real
Mitigación: corregir triggers y validar workflow antes de la demo.

### Riesgo: la sustentación se enfoca demasiado en Terraform
Mitigación: equilibrar infraestructura, dato, calidad y negocio.

---

## 10. Criterio de cierre de la fase

La fase se considera cerrada cuando:

- el catálogo describe correctamente raw y curated
- existe control de acceso básico
- logs, métricas y quarantine son demostrables
- la evolución de esquema está documentada
- la CI valida el repositorio
- hay evidencia suficiente para mostrar el pipeline en una sustentación

---

## 11. Checklist rápido

- [ ] catálogo Glue revisado
- [ ] permisos IAM validados
- [ ] placeholder o implementación de Lake Formation documentada
- [ ] logs y métricas disponibles
- [ ] policy de quarantine aplicada
- [ ] evolución de esquema documentada
- [ ] CI funcionando sobre la rama correcta
- [ ] evidencia lista para la defensa
