create or replace function make_booking_ref(p_booking_id bigint)
returns varchar
language plpgsql
as $$
declare
  v_ref varchar(12);
begin
  v_ref := 'BK' || lpad(p_booking_id::text, 10, '0');
  return v_ref;
end;
$$;

create or replace function trg_set_booking_ref()
returns trigger
language plpgsql
as $$
begin
  if new.booking_ref is null or new.booking_ref = '' then
    new.booking_ref := make_booking_ref(new.booking_id);
  end if;
  return new;
end;
$$;

drop trigger if exists set_booking_ref on bookings;
create trigger set_booking_ref
before insert on bookings
for each row
execute function trg_set_booking_ref();

create or replace function schedule_revenue(p_schedule_id bigint)
returns numeric
language sql
as $$
  select coalesce(sum(t.ticket_price), 0)
  from tickets t
  join bookings b on b.booking_id = t.booking_id
  where b.schedule_id = p_schedule_id;
$$;

create or replace function schedule_occupancy(p_schedule_id bigint)
returns integer
language sql
as $$
  select coalesce(count(*), 0)::int
  from tickets t
  join bookings b on b.booking_id = t.booking_id
  where b.schedule_id = p_schedule_id;
$$;

create or replace function trg_prevent_duplicate_seat()
returns trigger
language plpgsql
as $$
declare
  v_schedule_id bigint;
  v_exists int;
begin
  select b.schedule_id into v_schedule_id
  from bookings b
  where b.booking_id = new.booking_id;

  if v_schedule_id is null then
    raise exception 'Invalid booking_id: schedule not found';
  end if;

  select count(*) into v_exists
  from tickets t
  join bookings b2 on b2.booking_id = t.booking_id
  where b2.schedule_id = v_schedule_id
    and upper(t.seat_no) = upper(new.seat_no)
    and (tg_op = 'INSERT' or t.ticket_id <> new.ticket_id);

  if v_exists > 0 then
    raise exception 'Seat % is already taken for schedule_id %', new.seat_no, v_schedule_id;
  end if;

  new.seat_no := upper(new.seat_no);
  return new;
end;
$$;

drop trigger if exists prevent_duplicate_seat on tickets;
create trigger prevent_duplicate_seat
before insert or update on tickets
for each row
execute function trg_prevent_duplicate_seat();

create or replace function trg_confirm_booking_on_payment()
returns trigger
language plpgsql
as $$
begin
  update bookings
  set status = 'CONFIRMED'
  where booking_id = new.booking_id
    and status <> 'CANCELLED';
  return new;
end;
$$;

drop trigger if exists confirm_booking_on_payment on payments;
create trigger confirm_booking_on_payment
after insert on payments
for each row
execute function trg_confirm_booking_on_payment();
