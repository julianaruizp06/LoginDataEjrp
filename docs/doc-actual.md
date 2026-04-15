# 11. Estado actual del proyecto en AWS y decisión operativa sin streaming

## Objetivo de este documento

Dejar trazabilidad completa de:
- lo que ya se realizó en el repositorio,
- lo que ya se configuró en AWS,
- lo que ya se desplegó con Terraform,
- el punto exacto donde falló la arquitectura,
- y la decisión técnica de continuar el taller sin streaming, priorizando batch + data lake + Athena + Glue.

---

## 1. Contexto de la decisión

La arquitectura original del proyecto incluía:
- ingestión batch desde CSV,
- ingestión streaming con Kinesis,
- aterrizaje en S3,
- catálogo con Glue,
- consultas con Athena,
- y visualización posterior con dashboard.

Durante el despliegue real en AWS, la cuenta permitió crear correctamente la mayor parte de la arquitectura base, pero falló al crear los streams de Kinesis por una restricción asociada al plan actual de la cuenta.

Por esta razón, se decidió continuar el proyecto por el camino *batch/lakehouse*, dejando el componente de streaming documentado como diseño y evolución futura.

---

## 2. Lo realizado en el repositorio

### 2.1 Documentación
Se completaron documentos clave del proyecto, incluyendo:
- README del proyecto
- fases del proyecto
- troubleshooting
- relacional y NoSQL
- data warehouse
- streaming
- DataOps y calidad
- dashboard y QuickSight
- sustentación final

### 2.2 SQL de Athena
Se avanzó en la carpeta sql/athena con:
- creación de databases
- sanity checks raw
- CTAS para pedidos_curated
- CTAS para sensores_curated
- CTAS de dimensiones
- vista unificada vw_pedidos_unificados
- queries de insights

### 2.3 Terraform
Se corrigieron errores de sintaxis HCL en:
- backend.tf
- variables.tf
- módulos de athena, glue, iam, kinesis, firehose, naming

También se configuró:
- provider AWS usando perfil local logidata
- backend remoto en S3 para el state de Terraform

### 2.4 Makefile y requirements
Se dejó el proyecto más ejecutable localmente con:
- Makefile
- requirements.txt con pytest

---

## 3. Lo realizado en AWS

### 3.1 Seguridad y cuenta
Se completó la configuración inicial de la cuenta:
- cuenta AWS activa
- MFA activado en el usuario root
- alarma de billing creada
- suscripción SNS confirmada
- usuario IAM administrador creado: admin-logidata
- policy AdministratorAccess asignada
- MFA activado también para admin-logidata

### 3.2 AWS CLI
Se instaló y configuró AWS CLI correctamente.
Se validó el perfil:

- perfil: logidata
- región por defecto: us-east-2

También se verificó con aws sts get-caller-identity que las credenciales estaban funcionando correctamente.

### 3.3 Terraform backend
Se creó y configuró un bucket S3 para guardar el state remoto de Terraform.
Luego se configuró backend.tf en infra/terraform/envs/dev para usar ese bucket.

---

## 4. Lo que Terraform sí logró desplegar

El terraform plan del entorno dev fue exitoso.
El terraform apply alcanzó a crear correctamente varios recursos antes de fallar en streaming.

### Recursos creados o en muy buen estado
#### S3
- bucket raw
- bucket curated
- bucket de resultados de Athena
- versioning
- cifrado server-side
- public access block

#### Glue
- database logidata_raw
- database logidata_curated
- crawler raw_local
- crawler curated
- crawler raw_kinesis (aunque no se usará en esta fase)

#### Athena
- workgroup de Athena

#### IAM
- roles y policies necesarias para Glue y otras piezas base

---

## 5. Lo que falló

El despliegue falló específicamente al crear:
- stream de Kinesis para pedidos
- stream de Kinesis para sensores

El error observado fue equivalente a:
- restricción de acceso o suscripción requerida para el servicio Kinesis en el plan actual de la cuenta

### Consecuencia directa
Al no poder crear Kinesis:
- no se puede cerrar el flujo streaming real
- Firehose queda bloqueado o incompleto
- la parte raw_kinesis no debe usarse por ahora como fuente real del taller

---

## 6. Decisión técnica adoptada

Se continuará el proyecto por el camino *batch/lakehouse*, usando:

- archivos CSV locales
- carga manual a S3 raw
- Glue crawler raw_local
- Athena para consultas y CTAS
- capa curated
- dimensiones
- vista unificada
- insights
- dashboard

### Streaming queda
- documentado conceptualmente
- modelado en arquitectura
- justificado como evolución futura
- fuera del alcance ejecutado en esta cuenta mientras no se habilite Kinesis

---

## 7. Alcance vigente del proyecto

## Sí queda dentro del alcance ejecutable
- data lake en S3
- catálogo de datos con Glue
- consultas SQL con Athena
- curated layer
- dimensiones
- vista analítica
- insights
- visualización posterior
- evidencia para sustentación

## Queda fuera de la ejecución real por ahora
- Kinesis Data Streams
- Firehose operativo end-to-end
- consumo streaming real
- alertamiento near-real-time
- checkpointing real de streaming

---

## 8. Arquitectura que sí se va a ejecutar desde ahora

### Flujo batch
1. CSV locales en el repo
2. carga a s3://.../raw/local/...
3. ejecución del crawler raw_local
4. tablas raw en Glue/Athena
5. CTAS curated
6. dimensiones
7. vista unificada
8. queries de insights
9. dashboard

---

## 9. Justificación para la sustentación

Esta decisión es defendible porque:

- la arquitectura completa fue diseñada correctamente,
- la cuenta permitió validar una gran parte de la infraestructura,
- el bloqueo fue específico del componente streaming,
- el corazón analítico del taller sigue siendo completamente demostrable,
- se mantiene una solución funcional y coherente con el caso de negocio,
- y el streaming se presenta como siguiente fase de industrialización.

---

## 10. Estado actual resumido

### Estado del repositorio
- bien encaminado
- con documentación amplia
- con SQL analítico avanzado
- con Terraform operativo para la capa batch

### Estado de AWS
- cuenta segura
- CLI configurado
- IAM correcto
- billing protegido
- arquitectura parcial desplegada

### Próximo paso
Continuar el proyecto con:
- carga batch a S3
- Glue crawler raw_local
- Athena
- curated
- insights
- evidencia