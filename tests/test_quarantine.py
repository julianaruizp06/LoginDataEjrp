import os
from src.ingest.quarantine_writer import write_quarantine

def test_quarantine_writes_file(tmp_path):
    base_dir = str(tmp_path)
    out = write_quarantine(base_dir, dataset="pedidos", batch_id="b1", reason=["x"], raw_record={"a": 1})
    assert os.path.exists(out)