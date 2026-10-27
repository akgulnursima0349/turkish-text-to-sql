"""Validate Turkish Text-to-SQL seed files.

For every line in the given JSONL files, this script:
  1. checks that the required fields exist and are valid,
  2. builds the matching schema in an in-memory SQLite database,
  3. executes the SQL and reports whether it runs without errors.

Usage (from the repo root):
    python eval/validate_sql.py data/seed/ecommerce_seed.jsonl
    python eval/validate_sql.py data/seed/*.jsonl
"""

import json
import sqlite3
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

SCHEMAS = {
    "ecommerce": REPO_ROOT / "schemas" / "ecommerce.sql",
    "hr": REPO_ROOT / "schemas" / "hr.sql",
    "accounting": REPO_ROOT / "schemas" / "accounting.sql",
}

REQUIRED_FIELDS = ["id", "schema", "difficulty", "question", "sql"]
DIFFICULTIES = {"easy", "medium", "hard"}


def build_database(schema_name: str) -> sqlite3.Connection:
    """Create an in-memory database containing the given schema."""
    conn = sqlite3.connect(":memory:")
    conn.executescript(SCHEMAS[schema_name].read_text(encoding="utf-8"))
    return conn


def validate_record(record: dict, connections: dict) -> str | None:
    """Return an error message, or None if the record is valid."""
    missing = [field for field in REQUIRED_FIELDS if not record.get(field)]
    if missing:
        return f"missing fields: {', '.join(missing)}"

    if record["schema"] not in SCHEMAS:
        return f"unknown schema '{record['schema']}' (expected one of {sorted(SCHEMAS)})"

    if record["difficulty"] not in DIFFICULTIES:
        return f"unknown difficulty '{record['difficulty']}' (expected one of {sorted(DIFFICULTIES)})"

    schema_name = record["schema"]
    if schema_name not in connections:
        connections[schema_name] = build_database(schema_name)

    try:
        connections[schema_name].execute(record["sql"]).fetchall()
    except sqlite3.Error as error:
        return f"SQL error: {error}"

    return None


def main(paths: list[str]) -> int:
    if not paths:
        print(__doc__)
        return 2

    connections: dict[str, sqlite3.Connection] = {}
    seen_ids: set[str] = set()
    total = failed = 0

    for path in paths:
        for line_no, line in enumerate(Path(path).read_text(encoding="utf-8").splitlines(), start=1):
            if not line.strip():
                continue
            total += 1
            location = f"{path}:{line_no}"

            try:
                record = json.loads(line)
            except json.JSONDecodeError as error:
                failed += 1
                print(f"FAIL  {location}  invalid JSON: {error}")
                continue

            error = validate_record(record, connections)
            record_id = record.get("id", "?")

            if error is None and record_id in seen_ids:
                error = f"duplicate id '{record_id}'"
            seen_ids.add(record_id)

            if error:
                failed += 1
                print(f"FAIL  {location}  [{record_id}]  {error}")
            else:
                print(f"OK    {location}  [{record_id}]")

    print(f"\n{total - failed}/{total} passed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
