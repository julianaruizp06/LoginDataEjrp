> **Nota de alcance documental**
>
> Este documento describe una propuesta arquitectónica complementaria para sustentación y evolución futura del proyecto.
> La implementación más madura y verificable del repositorio está centrada en el enfoque Lakehouse sobre S3 + Glue + Athena + Airflow.
> Por lo tanto, cualquier referencia a componentes relacionales o NoSQL debe leerse como diseño propuesto o extensión arquitectónica, no necesariamente como infraestructura completamente desplegada en el estado actual del repo.

# 05. Relational & NoSQL

## Objetivo de esta capa

Definir la base transaccional y la base NoSQL que soportan el caso de LogiData S.A.S. para cubrir dos necesidades distintas:

- **Relacional**: consistencia, integridad referencial y carga inicial de entidades de negocio.
- **NoSQL**: almacenamiento eficiente de eventos de sensores IoT con acceso rápido por vehículo y tiempo.

> En el estado actual del repo, la implementación más avanzada está enfocada en el data lake y Athena. Este documento deja definido el diseño técnico que debe implementarse o explicarse en la sustentación para cubrir el bloque de bases de datos relacionales y NoSQL.

---

## 1. Diseño relacional propuesto en PostgreSQL / Amazon RDS

### Motor recomendado
- **Amazon RDS for PostgreSQL**
- Justificación:
  - soporta integridad referencial real con PK y FK,
  - es fácil de poblar desde CSV,
  - permite consultas SQL claras para validación académica,
  - es una elección realista para una capa operacional pequeña o staging relacional.

### Modelo relacional mínimo

#### Tabla `clientes`
- `id_cliente` VARCHAR PRIMARY KEY
- `nombre` VARCHAR NOT NULL
- `zona` VARCHAR NOT NULL
- `tipo_cliente` VARCHAR NOT NULL

Validaciones sugeridas:
- `zona IN ('Norte','Sur','Oriente','Occidente','Centro')`
- `tipo_cliente IN ('Retail','Farmacéutico','Supermercado','Ecommerce','Restaurante')`

#### Tabla `catalogo`
- `id_producto` VARCHAR PRIMARY KEY
- `categoria` VARCHAR NOT NULL
- `precio` NUMERIC(12,2) NOT NULL
- `tipo_entrega` VARCHAR NOT NULL

Validaciones sugeridas:
- `precio >= 0`
- `tipo_entrega IN ('Same Day','Next Day','Programada','Express')`

#### Tabla `pedidos`
- `id_pedido` VARCHAR PRIMARY KEY
- `id_cliente` VARCHAR NOT NULL REFERENCES clientes(id_cliente)
- `id_producto` VARCHAR NOT NULL REFERENCES catalogo(id_producto)
- `fecha` TIMESTAMP NOT NULL
- `monto` NUMERIC(12,2) NOT NULL
- `estado` VARCHAR NOT NULL

Validaciones sugeridas:
- `monto >= 0`
- `estado IN ('CREADO','EN_DESPACHO','ENTREGADO','CANCELADO')`

#### Tabla `entregas`
- `id_pedido` VARCHAR PRIMARY KEY REFERENCES pedidos(id_pedido)
- `hora_programada` TIMESTAMP NULL
- `hora_real` TIMESTAMP NULL
- `zona` VARCHAR NULL
- `conductor` VARCHAR NULL
- `vehiculo` VARCHAR NULL

### Relaciones principales

- `clientes (1) -> (N) pedidos`
- `catalogo (1) -> (N) pedidos`
- `pedidos (1) -> (0..1) entregas`

### Justificación técnica
Este modelo permite defender:
- **calidad estructural** por PK/FK,
- **trazabilidad operacional** desde cliente a pedido y entrega,
- **base confiable** para contrastar contra la capa analítica de Athena.

---

## 2. Carga inicial de CSV en PostgreSQL

### Estrategia recomendada
1. Crear esquema y tablas.
2. Cargar catálogos primero (`clientes`, `catalogo`).
3. Cargar `pedidos`.
4. Cargar `entregas`.
5. Ejecutar validaciones de integridad y conteo.

### Orden recomendado
1. `clientes.csv`
2. `catalogo.csv`
3. `pedidos.csv`
4. `entregas.csv`

### Validaciones posteriores a la carga
- conteo por tabla,
- pedidos sin cliente,
- pedidos sin producto,
- entregas sin pedido,
- estados inválidos,
- montos negativos.

### Entregable sugerido
Crear estos archivos en el repo:
- `sql/postgres/00_create_schema.sql`
- `sql/postgres/01_load_csv.sql`
- `sql/postgres/02_constraints.sql`

---

## 3. Diseño NoSQL propuesto en DynamoDB

### Caso de uso
Los sensores generan eventos de:
- temperatura,
- ubicación,
- timestamp,
- tipo de evento.

Ese patrón no necesita joins complejos, pero sí:
- alta escritura,
- consulta rápida por vehículo,
- acceso ordenado en el tiempo.

### Tabla propuesta: `sensores_eventos`

#### Claves
- **Partition Key**: `vehiculo`
- **Sort Key**: `timestamp`

#### Atributos
- `vehiculo`
- `timestamp`
- `latitud`
- `longitud`
- `temperatura`
- `evento`

### Justificación del diseño
- Permite consultar la historia de eventos de un vehículo ordenada cronológicamente.
- Facilita recuperar el último estado conocido por vehículo.
- Escala mejor que una tabla relacional para telemetría simple.

### Índices opcionales
#### GSI por evento
- PK: `evento`
- SK: `timestamp`

Sirve para preguntas como:
- ¿qué eventos `TEMP_CRITICA` hubo hoy?
- ¿cuántas alertas críticas ocurrieron en una ventana?

---

## 4. Estrategia de convivencia entre relacional y NoSQL

La defensa técnica debe explicar que no compiten; **se complementan**:

- **RDS/PostgreSQL**: entidades maestras y hechos transaccionales.
- **DynamoDB**: eventos IoT recientes y consultas rápidas operativas.
- **S3 + Glue + Athena**: capa analítica y de reporting.
- **Kinesis / Firehose**: movimiento del streaming hacia el lake.

---

## 5. Riesgos y decisiones

### Riesgo 1: duplicar almacenamiento
Sí, habrá redundancia parcial entre DynamoDB y S3 curated/raw.  
**Respuesta**: es una decisión intencional para separar operación rápida vs análisis histórico.

### Riesgo 2: inconsistencia de timestamps
Los CSV vienen UTC-agnósticos.  
**Respuesta**: documentar el supuesto y normalizar en ETL a un `timestamp` consistente.

### Riesgo 3: costos innecesarios
Levantar RDS y DynamoDB para un taller puede ser más costoso que usar solo lakehouse.  
**Respuesta**: para demo académica puede explicarse el diseño y dejar IaC preparado aunque la ejecución completa se haga en dev controlado.

---


