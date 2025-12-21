import os
from functools import wraps

from dotenv import load_dotenv
from flask import Flask, render_template, request, redirect, url_for, session, flash
from supabase import create_client, Client
from werkzeug.security import generate_password_hash, check_password_hash

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_SERVICE_ROLE_KEY")
FLASK_SECRET = os.getenv("FLASK_SECRET_KEY", "dev_secret")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise RuntimeError("Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env")

supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

app = Flask(__name__)
app.secret_key = FLASK_SECRET or "FLIGHT_DBMS_HARD_SECRET_KEY_123"



def login_required(fn):
    @wraps(fn)
    def wrapper(*args, **kwargs):
        if not session.get("user_id"):
            return redirect(url_for("login"))
        return fn(*args, **kwargs)
    return wrapper


def parse_dt(s: str) -> str:
    if not s:
        return ""
    s = s.replace("T", " ")
    if len(s) == 16:
        s += ":00"
    return s


@app.get("/login")
def login():
    return render_template("login.html")


@app.post("/login")
def login_post():
    username = request.form.get("username", "").strip()
    password = request.form.get("password", "").strip()

    if not username or not password:
        flash("Enter username and password.", "error")
        return redirect(url_for("login"))

    resp = supabase.table("users").select("*").eq("username", username).limit(1).execute()
    if not resp.data:
        flash("Invalid login.", "error")
        return redirect(url_for("login"))

    user = resp.data[0]
    stored_hash = user["password_hash"]

    if stored_hash == "demo_hash":
        flash("This seeded user has demo_hash. Register a new user from /register.", "error")
        return redirect(url_for("login"))

    if not check_password_hash(stored_hash, password):
        flash("Invalid login.", "error")
        return redirect(url_for("login"))

    session["user_id"] = user["user_id"]
    session["username"] = user["username"]
    session["role"] = "customer"
    return redirect(url_for("index"))


@app.get("/register")
def register():
    return render_template("register.html")


@app.post("/register")
def register_post():
    username = request.form.get("username", "").strip()
    email = request.form.get("email", "").strip()
    full_name = request.form.get("full_name", "").strip()
    phone = request.form.get("phone", "").strip()
    password = request.form.get("password", "").strip()

    if not username or not email or not full_name or not password:
        flash("Fill all required fields.", "error")
        return redirect(url_for("register"))

    pw_hash = generate_password_hash(password)

    try:
        ins = supabase.table("users").insert({
            "username": username,
            "email": email,
            "password_hash": pw_hash,
            "full_name": full_name,
            "phone": phone or None
        }).execute()
    except Exception as e:
        flash(f"Register failed: {e}", "error")
        return redirect(url_for("register"))

    user_id = ins.data[0]["user_id"]

    # ensure customer role exists, assign it
    role = supabase.table("roles").select("*").eq("role_name", "customer").limit(1).execute()
    if not role.data:
        r = supabase.table("roles").insert({"role_name": "customer", "description": "Book flights"}).execute()
        role_id = r.data[0]["role_id"]
    else:
        role_id = role.data[0]["role_id"]

    supabase.table("user_roles").insert({"user_id": user_id, "role_id": role_id}).execute()

    flash("Registered. Now login.", "ok")
    return redirect(url_for("login"))


@app.get("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.get("/")
@login_required
def index():
    return render_template("index.html")


@app.get("/schedules")
@login_required
def schedules():
    schedules_resp = supabase.table("flight_schedules").select("*").order("depart_at").execute()
    flights_resp = supabase.table("flights").select("*").execute()
    aircraft_resp = supabase.table("aircraft").select("*").execute()

    flights = {f["flight_id"]: f for f in flights_resp.data}
    aircraft = {a["aircraft_id"]: a for a in aircraft_resp.data}

    rows = []
    for s in schedules_resp.data:
        f = flights.get(s["flight_id"], {})
        a = aircraft.get(s["aircraft_id"], {})
        rows.append({
            **s,
            "flight_no": f.get("flight_no", ""),
            "aircraft_tail": a.get("tail_number", ""),
            "aircraft_model": a.get("model", ""),
            "seat_capacity": a.get("seat_capacity", "")
        })

    return render_template("schedules.html", schedules=rows, flights=list(flights.values()), aircraft=list(aircraft.values()))


@app.post("/schedules/add")
@login_required
def schedules_add():
    flight_id = request.form.get("flight_id")
    aircraft_id = request.form.get("aircraft_id")
    depart_at = parse_dt(request.form.get("depart_at"))
    arrive_at = parse_dt(request.form.get("arrive_at"))
    status = request.form.get("status", "SCHEDULED")
    gate = request.form.get("gate", "").strip() or None

    try:
        supabase.table("flight_schedules").insert({
            "flight_id": int(flight_id),
            "aircraft_id": int(aircraft_id),
            "depart_at": depart_at,
            "arrive_at": arrive_at,
            "status": status,
            "gate": gate
        }).execute()
        flash("Schedule added.", "ok")
    except Exception as e:
        flash(f"Add failed: {e}", "error")

    return redirect(url_for("schedules"))


@app.post("/schedules/update")
@login_required
def schedules_update():
    schedule_id = int(request.form.get("schedule_id"))
    status = request.form.get("status")
    gate = request.form.get("gate", "").strip() or None

    try:
        supabase.table("flight_schedules").update({
            "status": status,
            "gate": gate
        }).eq("schedule_id", schedule_id).execute()
        flash("Schedule updated.", "ok")
    except Exception as e:
        flash(f"Update failed: {e}", "error")

    return redirect(url_for("schedules"))


@app.post("/schedules/delete")
@login_required
def schedules_delete():
    schedule_id = int(request.form.get("schedule_id"))
    try:
        supabase.table("flight_schedules").delete().eq("schedule_id", schedule_id).execute()
        flash("Schedule deleted.", "ok")
    except Exception as e:
        flash(f"Delete failed: {e}", "error")
    return redirect(url_for("schedules"))


@app.get("/bookings")
@login_required
def bookings():
    bookings_resp = supabase.table("bookings").select("*").order("booked_at", desc=True).execute()
    users_resp = supabase.table("users").select("user_id,username,full_name").execute()
    schedules_resp = supabase.table("flight_schedules").select("schedule_id,flight_id,depart_at,status").execute()
    flights_resp = supabase.table("flights").select("flight_id,flight_no").execute()

    users = {u["user_id"]: u for u in users_resp.data}
    flights = {f["flight_id"]: f for f in flights_resp.data}

    sched_rows = []
    for s in schedules_resp.data:
        sched_rows.append({
            **s,
            "flight_no": flights.get(s["flight_id"], {}).get("flight_no", "")
        })
    schedules_map = {s["schedule_id"]: s for s in sched_rows}

    rows = []
    for b in bookings_resp.data:
        u = users.get(b["user_id"], {})
        s = schedules_map.get(b["schedule_id"], {})
        rows.append({
            **b,
            "username": u.get("username", ""),
            "full_name": u.get("full_name", ""),
            "flight_no": s.get("flight_no", ""),
            "depart_at": s.get("depart_at", ""),
            "schedule_status": s.get("status", "")
        })

    return render_template("bookings.html", bookings=rows, users=list(users.values()), schedules=sched_rows)


@app.post("/bookings/add")
@login_required
def bookings_add():
    user_id = int(request.form.get("user_id"))
    schedule_id = int(request.form.get("schedule_id"))
    status = request.form.get("status", "PENDING")

    try:
        supabase.table("bookings").insert({
            "user_id": user_id,
            "schedule_id": schedule_id,
            "booking_ref": "",
            "status": status
        }).execute()
        flash("Booking added.", "ok")
    except Exception as e:
        flash(f"Add failed: {e}", "error")

    return redirect(url_for("bookings"))


@app.post("/bookings/update")
@login_required
def bookings_update():
    booking_id = int(request.form.get("booking_id"))
    status = request.form.get("status")

    try:
        supabase.table("bookings").update({
            "status": status
        }).eq("booking_id", booking_id).execute()
        flash("Booking updated.", "ok")
    except Exception as e:
        flash(f"Update failed: {e}", "error")

    return redirect(url_for("bookings"))


@app.post("/bookings/delete")
@login_required
def bookings_delete():
    booking_id = int(request.form.get("booking_id"))
    try:
        supabase.table("bookings").delete().eq("booking_id", booking_id).execute()
        flash("Booking deleted.", "ok")
    except Exception as e:
        flash(f"Delete failed: {e}", "error")
    return redirect(url_for("bookings"))


@app.get("/tickets")
@login_required
def tickets():
    tickets_resp = supabase.table("tickets").select("*").order("issued_at", desc=True).execute()
    bookings_resp = supabase.table("bookings").select("booking_id,booking_ref,schedule_id").execute()
    schedules_resp = supabase.table("flight_schedules").select("schedule_id,flight_id,depart_at").execute()
    flights_resp = supabase.table("flights").select("flight_id,flight_no").execute()

    bookings_map = {b["booking_id"]: b for b in bookings_resp.data}
    schedules_map = {s["schedule_id"]: s for s in schedules_resp.data}
    flights_map = {f["flight_id"]: f for f in flights_resp.data}

    rows = []
    for t in tickets_resp.data:
        b = bookings_map.get(t["booking_id"], {})
        s = schedules_map.get(b.get("schedule_id"), {})
        f = flights_map.get(s.get("flight_id"), {})
        rows.append({
            **t,
            "booking_ref": b.get("booking_ref", ""),
            "schedule_id": b.get("schedule_id", ""),
            "flight_no": f.get("flight_no", ""),
            "depart_at": s.get("depart_at", "")
        })

    return render_template("tickets.html", tickets=rows, bookings=list(bookings_map.values()))


@app.post("/tickets/add")
@login_required
def tickets_add():
    booking_id = int(request.form.get("booking_id"))
    passenger_name = request.form.get("passenger_name", "").strip()
    passport_no = request.form.get("passport_no", "").strip() or None
    seat_no = request.form.get("seat_no", "").strip().upper()
    ticket_price = float(request.form.get("ticket_price", "0") or 0)

    if not passenger_name or not seat_no:
        flash("Passenger name and seat are required.", "error")
        return redirect(url_for("tickets"))

    try:
        supabase.table("tickets").insert({
            "booking_id": booking_id,
            "passenger_name": passenger_name,
            "passport_no": passport_no,
            "seat_no": seat_no,
            "ticket_price": ticket_price
        }).execute()
        flash("Ticket added.", "ok")
    except Exception as e:
        flash(f"Add failed: {e}", "error")

    return redirect(url_for("tickets"))


@app.post("/tickets/update")
@login_required
def tickets_update():
    ticket_id = int(request.form.get("ticket_id"))
    seat_no = request.form.get("seat_no", "").strip().upper()
    ticket_price = float(request.form.get("ticket_price", "0") or 0)

    try:
        supabase.table("tickets").update({
            "seat_no": seat_no,
            "ticket_price": ticket_price
        }).eq("ticket_id", ticket_id).execute()
        flash("Ticket updated.", "ok")
    except Exception as e:
        flash(f"Update failed: {e}", "error")

    return redirect(url_for("tickets"))


@app.post("/tickets/delete")
@login_required
def tickets_delete():
    ticket_id = int(request.form.get("ticket_id"))
    try:
        supabase.table("tickets").delete().eq("ticket_id", ticket_id).execute()
        flash("Ticket deleted.", "ok")
    except Exception as e:
        flash(f"Delete failed: {e}", "error")
    return redirect(url_for("tickets"))


if __name__ == "__main__":
    app.run(debug=True)
