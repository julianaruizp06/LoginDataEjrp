# 08. DataOps & Quality

## Objetivo de esta capa

Asegurar que el proyecto no solo cargue datos, sino que lo haga con:
- control de calidad,
- repetibilidad,
- versionamiento,
- validación técnica básica,
- evidencia para sustentación.

---

## 1. Principios aplicados

### Repetibilidad
La infraestructura y los scripts deben poder ejecutarse de forma consistente.

### Validación temprana
Los errores deben detectarse lo más cerca posible de la entrada.

### Separación de capas
- raw,
- curated,
- quarantine,
- system / manifests.

### Evidencia
Cada fase debe dejar trazas, resultados o screenshots.

---

## 2. Estrategia de calidad de datos

### Validaciones mínimas obligatorias
1. Conteo de registros por tabla.
2. Nulos en claves relevantes.
3. Validación de dominios:
   - `estado`
   - `evento`
4. Duplicados potenciales:
   - `id_pedido`
   - `vehiculo + timestamp`

### Validaciones recomendadas
- montos no negativos,
- precios no negativos,
- fechas parseables,
- entregas asociadas a pedidos existentes,
- sensores con vehículo informado.

---

## 3. Quarantine

### Objetivo
Aislar registros inválidos para no contaminar la capa raw o curated.

### Cuándo enviar a quarantine
- columnas obligatorias faltantes,
- dominio inválido,
- cast imposible,
- estructura rota.

### Qué guardar
- payload original,
- error de validación,
- timestamp de proceso,
- dataset origen.

---

## 4. Great Expectations

### Rol en el taller
No es obligatorio ejecutarlo desde el día 1, pero sí es muy útil para defender calidad formal.

### Suites mínimas sugeridas
#### Para `pedidos`
- `id_pedido` no nulo
- `id_cliente` no nulo
- `id_producto` no nulo
- `estado` dentro del conjunto permitido
- `monto >= 0`

#### Para `sensores`
- `vehiculo` no nulo
- `timestamp` no nulo
- `temperatura` no nula
- `evento` dentro del conjunto permitido

### Evidencia recomendada
- Data Docs exportados,
- screenshot del resultado,
- archivo JSON/YAML de expectativas.

---

## 5. Orquestación

### Recomendación
Para la historia de usuario de DataOps, el diseño mínimo defendible es con **Airflow**.

### DAG 1: batch_ingestion
Tareas sugeridas:
1. cargar datasets raw,
2. validar estructura,
3. escribir manifests,
4. correr sanity checks.

### DAG 2: curated_build
Tareas sugeridas:
1. ejecutar CTAS curated,
2. construir dimensiones,
3. crear vista unificada,
4. ejecutar queries de control.

> Si Airflow aún no está implementado en el repo, este documento debe presentarlo como la orquestación objetivo de siguiente fase.

---

## 6. CI/CD

### Estado actual esperado
El repo ya tiene pipeline básico en GitHub Actions para:
- `terraform fmt`,
- `terraform validate`,
- `pytest`.

### Mejora recomendada
Agregar:
- lint básico de SQL o validación sintáctica,
- verificación de archivos requeridos,
- control de formato de Markdown.

### Flujo recomendado
1. cambio en rama feature,
2. push,
3. validación automática,
4. merge a rama principal de trabajo,
5. despliegue controlado.

---

## 7. Makefile y experiencia de ejecución

El `Makefile` debe facilitar:
- instalación,
- pruebas,
- formateo Terraform,
- validación Terraform,
- plan básico.

Esto hace el proyecto más defendible, porque demuestra intención de automatización y orden operativo.

---

## 8. Qué mostrar en la sustentación

- qué validaciones ejecutas,
- qué pasa si un dato es inválido,
- cómo separas quarantine,
- qué automatiza CI,
- qué automatizaría Airflow,
- cómo garantizas reproducibilidad.

---

## 9. Riesgos y respuestas útiles

### “¿Dónde está la calidad si no ejecutaste Great Expectations completo?”
Respuesta:
> La calidad ya está planteada en tres niveles: validación inicial, sanity checks en Athena y diseño formal de expectativas para industrializar el pipeline.

### “¿Por qué Airflow y no solo scripts?”
Respuesta:
> Porque Airflow aporta dependencia entre tareas, reintentos, observabilidad, calendario y trazabilidad operativa.

---

## 10. Estado esperado del repo

Idealmente esta historia debe cerrar con:
- `Makefile`,
- `requirements.txt` con `pytest`,
- pruebas unitarias,
- sanity checks en SQL,
- documentación de DAGs,
- documentación de calidad,
- evidencias en `evidence/`.
