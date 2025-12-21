# Flight DBMS (Supabase PostgreSQL + Flask)

## Project Contents
- ERD diagram: `/ERD`
- SQL scripts: `/sql`
  - ddl.sql (tables + constraints)
  - functions_triggers.sql (functions + triggers)
  - dml_seed.sql (sample data)
  - queries.sql (management queries)
- Flask GUI: `/app`

## Run Flask GUI
1. Create `/app/.env`:
SUPABASE_URL=...
SUPABASE_SERVICE_ROLE_KEY=...
FLASK_SECRET_KEY=...

2. Install:
pip install -r app/requirements.txt

3. Run:
python app/app.py

Open: http://127.0.0.1:5000/
