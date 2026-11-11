from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo

source = Path(__file__).resolve().parent
entry = ZipInfo("handler.py")
entry.external_attr = 0o100644 << 16

with ZipFile(source / "lambda.zip", "w") as bundle:
    bundle.writestr(entry, (source / "lambda" / "handler.py").read_bytes(), ZIP_DEFLATED)
