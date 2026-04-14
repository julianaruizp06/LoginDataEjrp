from src.ingest.validator import load_contract, validate_row

def test_validate_row_missing_required():
    contract = load_contract("docs/data-contracts/pedidos.v1.json")
    row = {"id_pedido": "1"}  # faltan campos
    errors = validate_row(contract, row)
    assert any(e.startswith("missing_required:") for e in errors)

def test_validate_row_allowed_values():
    contract = load_contract("docs/data-contracts/pedidos.v1.json")
    row = {
        "id_pedido": "1",
        "id_cliente": "1",
        "id_producto": "1",
        "fecha": "2026-02-25T15:40:00Z",
        "monto": "120.5",
        "estado": "MALO"
    }
    errors = validate_row(contract, row)
    assert "invalid_value:estado" in errors