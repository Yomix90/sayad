"""Import spots or shops into the Sayad server database from the command line.

  python import_spots.py --scan                       # list importable files of OLD_APP_DIR
  python import_spots.py "../old app/ast.db" --dry-run
  python import_spots.py "../old app/ast.db" --table Masaid --source old_app
  python import_spots.py "../old app/downloaded_dbs/asx.db" --into shops

The same import is available in the dashboard (/admin, "Import" tab).
"""
import argparse
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import app as server  # noqa: E402
import importer  # noqa: E402


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('file', nargs='?')
    ap.add_argument('--scan', action='store_true', help='list importable files in OLD_APP_DIR')
    ap.add_argument('--table', help='SQLite table (auto-detected otherwise)')
    ap.add_argument('--into', choices=['spots', 'shops'], help='target (guessed from the table name)')
    ap.add_argument('--source', default='old_app')
    ap.add_argument('--pending', action='store_true', help='import as pending instead of approved')
    ap.add_argument('--dry-run', action='store_true')
    a = ap.parse_args()

    if a.scan or not a.file:
        for f in importer.scan(server.OLD_APP_DIR):
            print(f"{f['file']:40s} {f['table'] or '-':12s} {f['rows']:6d} rows -> {f['target']}"
                  + (f"  ERROR {f['error']}" if f.get('error') else ''))
        return

    server.init_db()
    r = importer.import_file(server.DB_PATH, a.file, table=a.table, into=a.into,
                             status='pending' if a.pending else 'approved',
                             source=a.source, dry_run=a.dry_run)
    print(json.dumps(r, ensure_ascii=False, indent=2))


if __name__ == '__main__':
    main()
