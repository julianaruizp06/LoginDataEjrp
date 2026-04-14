# Troubleshooting

Guía rápida de resolución de problemas para el proyecto LogiData Lakehouse.

---

## 1. Terraform no inicializa el backend remoto

### Síntoma
`terraform init` falla al conectar el backend S3 o al usar la tabla DynamoDB de locking.

### Posibles causas
- bucket de state no existe
- tabla de lock no existe
- región incorrecta
- credenciales AWS no configuradas
- nombre del backend mal parametrizado

### Qué revisar
1. Ejecutar el bootstrap primero.
2. Confirmar región y nombres del backend.
3. Verificar credenciales con `aws sts get-caller-identity`.
4. Revisar que el bucket tenga versionado y cifrado.
5. Revisar que el comando `terraform init` incluya `-backend-config` si aplica.

---

## 2. Terraform validate o plan falla en módulos

### Síntoma
Errores por variables no definidas, referencias a outputs inexistentes o recursos duplicados.

### Posibles causas
- `terraform.tfvars` incompleto
- ambiente `dev` o `prod` sin valores consistentes
- cambios en módulos sin actualizar outputs
- nombres de recursos no válidos para AWS

### Qué revisar
- `variables.tf`
- `terraform.tfvars`
- `outputs.tf`
- restricciones de naming AWS
- `terraform fmt -recursive`

---

## 3. El workflow de CI no corre sobre la rama correcta

### Síntoma
Se hace push y GitHub Actions no ejecuta validaciones.

### Posibles causas
- la rama no está incluida en `.github/workflows/ci.yml`
- el trigger solo escucha `main` u otras ramas

### Qué hacer
- revisar `on.push.branches`
- revisar `on.pull_request.branches`
- incluir explícitamente la rama de trabajo real
- confirmar que el YAML no tenga errores de indentación

---

## 4. Los archivos llegan a S3 pero Athena no los ve

### Síntoma
Los objetos existen en S3 raw o curated, pero no aparecen en Athena.

### Posibles causas
- crawler no ejecutado
- tabla creada en otra database
- particiones no detectadas
- ruta S3 equivocada
- Glue sin permisos suficientes

### Qué revisar
1. Confirmar ubicación física del dataset.
2. Revisar Glue Data Catalog.
3. Ejecutar o re-ejecutar crawler.
4. Confirmar la database usada en Athena.
5. Si la tabla es explícita, validar `LOCATION` y formato.

---

## 5. Athena ve la tabla pero la consulta falla

### Síntoma
Errores de formato, tipos, columnas nulas inesperadas o resultados vacíos.

### Posibles causas
- delimitador incorrecto
- headers mal interpretados
- tipos detectados incorrectamente por crawler
- partición sin datos
- mezcla de archivos incompatibles en el mismo prefijo

### Qué hacer
- validar manualmente muestra del archivo
- revisar definición de tabla
- aislar un dataset por prefijo
- usar CTAS para reescribir a Parquet
- evitar mezclar datasets distintos en la misma ruta

---

## 6. Firehose no aterriza eventos en S3

### Síntoma
Se publican eventos a Kinesis pero no aparecen en raw.

### Posibles causas
- Firehose sin permisos IAM
- stream equivocado
- buffer aún no se vacía
- prefijo de salida mal configurado
- error de escritura enviado a ruta de error

### Qué revisar
- estado del delivery stream
- política IAM de Firehose
- CloudWatch si se habilita logging
- prefijos de output y error output
- cantidad de eventos enviados y tiempo de buffer

---

## 7. El productor de streaming no publica

### Síntoma
El script Python falla o no genera eventos en Kinesis.

### Posibles causas
- nombre del stream incorrecto
- región AWS equivocada
- credenciales no cargadas
- endpoint o dataset de entrada mal ubicado

### Qué hacer
- revisar variables de entorno
- validar nombre exacto del stream
- probar publicación de un solo evento
- registrar logs por intento
- confirmar con AWS CLI que el stream existe

---

## 8. Los validadores mandan demasiados registros a quarantine

### Síntoma
El porcentaje de quarantine es mucho mayor al esperado.

### Posibles causas
- contrato desactualizado
- tipo de dato interpretado distinto al contrato
- valores permitidos incompletos
- archivos con formato inconsistente

### Qué hacer
1. revisar una muestra del archivo original
2. revisar el contrato versionado
3. inspeccionar razones de quarantine
4. corregir contrato o transformar antes de validar
5. repetir prueba con un subconjunto pequeño

---

## 9. No se generan manifests o métricas

### Síntoma
Se procesan datos pero no queda evidencia en `_system` o `evidence/monitoring`.

### Posibles causas
- función de escritura no invocada
- ruta de salida incorrecta
- permisos faltantes
- batch_id no generado

### Qué revisar
- orden de ejecución del pipeline
- ruta configurada
- manejo de excepciones
- existencia del directorio local o prefijo S3

---

## 10. El crawler crea tipos incorrectos

### Síntoma
Athena interpreta números como string o fechas como texto.

### Causa típica
Los crawlers son útiles, pero no siempre infieren bien tipos sensibles.

### Solución recomendada
- usar crawler solo para raw
- fijar esquema explícito para curated
- reescribir tablas analíticas en Parquet
- documentar el esquema final esperado

---

## 11. No hay evidencia suficiente para sustentar

### Síntoma
El pipeline funciona parcialmente, pero no hay material convincente para mostrar.

### Qué debe existir como mínimo
- diagrama de arquitectura
- capturas de S3
- capturas de Glue
- capturas de Athena
- muestra de quarantine
- logs y métricas
- explicación por fases
- lista de decisiones de diseño

### Recomendación
Cada avance técnico debe dejar una evidencia visual o un archivo demostrable.

---

## 12. Problemas frecuentes de narrativa técnica

### Problema
Explicar solo infraestructura y no el valor del dato.

### Corrección
Siempre conectar:
- fuente
- control de calidad
- dataset curado
- KPI
- decisión de negocio habilitada

### Problema
Mostrar solo el happy path.

### Corrección
Incluir quarantine, errores y cómo se detectan.

### Problema
No justificar decisiones.

### Corrección
Explicar por qué:
- S3 para storage
- Kinesis para eventos
- Glue para metadatos
- Athena para consulta rápida
- Terraform para reproducibilidad

---

## 13. Checklist final de soporte

- [ ] backend Terraform validado
- [ ] ambiente dev desplegado
- [ ] objetos en S3 verificados
- [ ] Glue catalogando datasets
- [ ] Athena consultando tablas
- [ ] streaming aterrizando en raw
- [ ] quarantine generando evidencia
- [ ] métricas y logs disponibles
- [ ] CI ejecutando sobre la rama correcta
- [ ] material de demo preparado
