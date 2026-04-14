# Schema Evolution (MVP)

- Columnas nuevas: OK (backward compatible).
- Cambios de tipo, renombres o remoción: nueva versión de contrato (v2, v3...).
- Cada cambio debe venir con:
  - actualización de contrato
  - ajuste de validador (si aplica)
  - test nuevo en tests/