# Fase 1 — Foundations

Esta fase establece los cimientos técnicos del proyecto. Aquí no se busca todavía “tener todo funcionando”, sino dejar una base coherente, reproducible y entendible para soportar ingestión, curación, consulta y gobierno.

---

## 1. Objetivo

Definir y documentar:

- arquitectura base del lakehouse
- convención de nombres
- layout del data lake en S3
- contratos iniciales de datos
- política de quarantine
- observabilidad mínima
- bootstrap de infraestructura con Terraform

---

## 2. Alcance de la fase

### Incluye
- documento de arquitectura
- diagramas de alto nivel
- naming estándar
- estructura `raw / curated / quarantine / _system`
- contratos v1 para datasets críticos
- bootstrap Terraform para backend remoto
- ambiente `dev` parametrizado

### No incluye aún
- modelo analítico final completo
- dashboard final
- orquestación compleja
- monitoreo avanzado
- gobierno fino con Lake Formation a nivel granular

---

## 3. Decisiones de diseño

## 3.1 S3 como fuente de verdad
Se utiliza S3 como **single source of truth** porque:

- separa almacenamiento de cómputo
- permite retener raw sin transformar
- es económico para datasets académicos y escalable para crecimiento
- facilita integración con Glue, Athena y Firehose

## 3.2 Cuatro zonas del lago
Se definen cuatro capas para evitar mezclar propósitos:

### Raw
Contiene el dato tal como llegó.

```text
raw/<source>/<dataset>/ingest_date=YYYY-MM-DD/
```

### Curated
Contiene datasets limpios y listos para análisis.

```text
curated/<domain>/<dataset>/event_date=YYYY-MM-DD/
```

### Quarantine
Contiene registros inválidos con contexto del error.

```text
quarantine/<source>/<dataset>/ingest_date=YYYY-MM-DD/batch_id=<id>/
```

### _system
Contiene metadata operativa y manifests.

```text
_system/metadata/manifests/<dataset>/
```

## 3.3 Contratos de datos desde el principio
La validación no debe empezar al final. Se definen contratos v1 mínimos para:

- `pedidos`
- `sensores`

Esto reduce el riesgo de contaminar raw y deja trazabilidad sobre compatibilidad de esquema.

---

## 4. Entregables de la fase

- `docs/00-overview.md`
- `docs/01-phase-1-foundations.md`
- `docs/data-contracts/pedidos.v1.json`
- `docs/data-contracts/sensores.v1.json`
- `docs/quarantine-policy.md`
- `docs/observability.md`
- `docs/schema-evolution.md`
- `infra/terraform/bootstrap/*`
- `infra/terraform/envs/dev/*`
- diagramas base en `diagrams/`

---

## 5. Naming estándar

### Variables lógicas
- `project`: nombre del caso o solución
- `prefix`: prefijo corto del equipo
- `group`: identificador del grupo
- `environment`: `dev` o `prod`
- `region`: región AWS

### Reglas
- usar minúsculas y guiones
- evitar nombres ambiguos
- separar nombres de buckets y recursos lógicos
- parametrizar por ambiente en Terraform

### Ejemplo
```text
resource_prefix = ejrp-g01-dev
raw_bucket_name = ejrp-g01-raw-ejrp
curated_bucket_name = ejrp-g01-curated-ejrp
athena_results_bucket_name = ejrp-g01-athena-results-ejrp
```

---

## 6. Bootstrap de infraestructura

El bootstrap se usa para crear el backend remoto de Terraform.

### Recursos esperados
- bucket S3 para `tfstate`
- tabla DynamoDB para locking

### Beneficios
- evita estado local frágil
- soporta colaboración
- bloquea ejecuciones concurrentes de Terraform

### Buenas prácticas
- activar versionado del bucket
- cifrado server-side
- bloquear acceso público
- usar nombres independientes del ambiente si así se definió el patrón

---

## 7. Layout de evidencia y trazabilidad

Esta fase también define dónde quedarán las evidencias.

### Local / repo
```text
evidence/logs/
evidence/monitoring/
evidence/samples/
```

### Qué guardar
- logs JSONL por ejecución
- métricas por batch
- muestra de quarantine
- screenshots de recursos AWS
- salida de consultas Athena
- capturas del catálogo Glue

---

## 8. Tareas concretas de implementación

1. Revisar datasets fuente.
2. Confirmar nombres, tipos y dominios permitidos.
3. Crear contratos v1.
4. Formalizar layout S3.
5. Crear bootstrap Terraform.
6. Parametrizar ambiente `dev`.
7. Validar `terraform fmt` y `terraform validate`.
8. Documentar arquitectura y fases.
9. Versionar diagramas y evidencia.

---

## 9. Errores comunes en esta fase

### Error 1: comenzar por transformar datos sin definir raw
Consecuencia: se pierde trazabilidad y no existe una capa confiable de re-proceso.

### Error 2: no documentar naming
Consecuencia: nombres inconsistentes entre ambientes y recursos difíciles de encontrar.

### Error 3: no usar contratos iniciales
Consecuencia: el pipeline acepta basura y quarantine llega tarde.

### Error 4: dejar Terraform con estado local
Consecuencia: riesgo alto de drift o pérdida del estado.

### Error 5: mezclar evidencia con datos operativos
Consecuencia: el repo se vuelve desordenado y difícil de defender en una sustentación.

---

## 10. Criterio de cierre de la fase

La fase se considera cerrada cuando:

- existe un documento claro de arquitectura
- el naming es consistente
- el layout S3 está definido
- al menos dos contratos de datos están versionados
- bootstrap y ambiente `dev` son ejecutables
- hay evidencia mínima de validación y estructura del proyecto

---

## 11. Checklist rápido

- [ ] Arquitectura documentada
- [ ] Naming definido
- [ ] S3 layout definido
- [ ] Contratos v1 creados
- [ ] Quarantine policy documentada
- [ ] Observabilidad MVP documentada
- [ ] Bootstrap Terraform listo
- [ ] Ambiente `dev` parametrizado
- [ ] Diagramas exportados
