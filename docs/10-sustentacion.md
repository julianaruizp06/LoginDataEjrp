# 10. Sustentación final

## Objetivo

Defender el proyecto de forma técnica, clara y orientada a decisiones de arquitectura, mostrando que la solución responde al caso de negocio y que el diseño es implementable en AWS.

---

## 1. Estructura sugerida de la exposición

### 1. Contexto del negocio
Explicar brevemente:
- quién es LogiData,
- qué problema tiene,
- por qué necesita una plataforma moderna de datos.

### 2. Arquitectura propuesta
Mostrar el diagrama y recorrer el flujo:
- fuentes CSV,
- sensores,
- S3 raw,
- Kinesis / Firehose,
- Glue,
- Athena,
- curated,
- dashboard.

### 3. Gobierno y calidad
Explicar:
- contratos,
- validaciones,
- quarantine,
- catálogo,
- CI/CD.

### 4. Modelo analítico
Explicar:
- curated,
- dimensiones,
- vista unificada,
- KPIs.

### 5. Dashboard
Mostrar métricas y lectura de negocio.

### 6. Roadmap
Decir qué está implementado y qué queda como evolución.

---

## 2. Cómo explicar la arquitectura

### Mensaje simple
> Separé la solución en una capa de ingestión, una capa de gobierno y una capa de consumo analítico.

### Mensaje técnico
> Usé S3 como data lake, Glue como catálogo, Athena como motor serverless de consulta, Kinesis/Firehose para streaming de sensores y SQL curated para construir una base analítica lista para QuickSight.

### Justificación por servicio
- **S3**: económico, escalable, estándar para lakehouse.
- **Glue**: catálogo administrado y descubrimiento de tablas.
- **Athena**: consultas SQL sin administrar clúster.
- **Kinesis / Firehose**: ingestión streaming simple.
- **QuickSight**: visualización nativa en AWS.
- **Terraform**: reproducibilidad de infraestructura.

---

## 3. Preguntas difíciles esperables y cómo responderlas

### “¿Por qué no usaste Redshift?”
Respuesta:
> Para este alcance, Athena fue suficiente porque el volumen es moderado, el patrón es exploratorio y queríamos reducir operación de infraestructura.

### “¿Por qué no usaste Spark en todo?”
Respuesta:
> Porque para el volumen del caso, CTAS en Athena cubre bien una primera versión. Spark queda como evolución para mayor transformación, incrementalidad y streaming avanzado.

### “¿Dónde está el gobierno?”
Respuesta:
> Está en la separación de capas, catálogo, convenciones de nombres, validaciones, quarantine, control de acceso y trazabilidad documental.

### “¿Cómo manejas calidad?”
Respuesta:
> Con validaciones tempranas, sanity checks, control de dominios, nulos, duplicados y diseño de expectativas formales.

### “¿Cómo escalaría esta arquitectura?”
Respuesta:
> El patrón ya es escalable porque desacopla ingestión, almacenamiento y consumo. Si el volumen crece, se puede evolucionar a Spark/Glue Jobs, particionado más fino, Redshift o streaming avanzado.

### “¿Qué tan costosa es?”
Respuesta:
> Es una arquitectura eficiente para un caso académico y un MVP productivo pequeño porque usa varios servicios serverless y evita infraestructura persistente compleja.

---

## 4. Qué debes decir con honestidad

En la sustentación, no conviene exagerar.  
Debes distinguir entre:

### Implementado
- estructura del lake,
- Terraform base,
- SQL curated,
- documentación,
- CI básico,
- diseño del dashboard.

### Diseñado / siguiente fase
- RDS relacional,
- DynamoDB,
- Airflow completo,
- Great Expectations ejecutado end-to-end,
- streaming avanzado con checkpointing real.

Eso te hace ver más sólido, no más débil.

---

## 5. Demo recomendada

### Demo mínima
1. mostrar repo y estructura,
2. mostrar arquitectura,
3. abrir SQL curated,
4. mostrar vista unificada,
5. mostrar queries de insights,
6. mostrar dashboard o mock del dashboard,
7. cerrar con riesgos y evolución.

### Demo ideal
Agregar:
- evidencia de S3,
- Glue catalog,
- Athena ejecutando queries,
- screenshots de resultados.

---

## 6. Frases útiles para defender decisiones

- “Priorizamos una solución realista, implementable y serverless.”
- “Separé capa operacional y capa analítica para no mezclar necesidades.”
- “El modelo curated traduce datos crudos en indicadores de negocio.”
- “La calidad no depende de una sola herramienta; está distribuida en validación, quarantine y controles analíticos.”
- “El diseño deja una ruta clara de industrialización.”

---

## 7. Checklist antes de sustentar

- repo limpio y consistente,
- README claro,
- diagramas visibles,
- SQL sin placeholders rotos,
- bucket real o aclaración explícita de placeholder,
- screenshots en `evidence/`,
- narrativa de 5 a 7 minutos preparada,
- respuestas de costo, escalabilidad, gobierno y calidad listas.

---

## 8. Cierre sugerido

> La propuesta entrega una base moderna de datos en AWS, capaz de integrar fuentes batch y streaming, con gobierno básico, trazabilidad, analítica operativa y una ruta clara de escalamiento.
