import sqlite3
conn = sqlite3.connect('db.sqlite3')
c = conn.cursor()
c.execute("SELECT name, sql FROM sqlite_master WHERE type='table' ORDER BY name")
for name, sql in c.fetchall():
    print(f"=== {name} ===")
    print(sql)
    print()
