select
  s.schedule_id,
  f.flight_no,
  ap1.iata_code as from_iata,
  ap2.iata_code as to_iata,
  s.depart_at,
  s.arrive_at,
  s.status,
  a.tail_number,
  a.model
from flight_schedules s
join flights f on f.flight_id = s.flight_id
join airports ap1 on ap1.airport_id = f.from_airport_id
join airports ap2 on ap2.airport_id = f.to_airport_id
join aircraft a on a.aircraft_id = s.aircraft_id
order by s.depart_at;

select
  f.flight_no,
  count(*) as total_bookings
from bookings b
join flight_schedules s on s.schedule_id = b.schedule_id
join flights f on f.flight_id = s.flight_id
group by f.flight_no
order by total_bookings desc;

select
  s.schedule_id,
  f.flight_no,
  coalesce(sum(t.ticket_price),0) as revenue
from flight_schedules s
join flights f on f.flight_id = s.flight_id
left join bookings b on b.schedule_id = s.schedule_id
left join tickets t on t.booking_id = b.booking_id
group by s.schedule_id, f.flight_no
order by revenue desc;

select
  ap1.iata_code as from_iata,
  ap2.iata_code as to_iata,
  count(t.ticket_id) as tickets_sold
from tickets t
join bookings b on b.booking_id = t.booking_id
join flight_schedules s on s.schedule_id = b.schedule_id
join flights f on f.flight_id = s.flight_id
join airports ap1 on ap1.airport_id = f.from_airport_id
join airports ap2 on ap2.airport_id = f.to_airport_id
group by ap1.iata_code, ap2.iata_code
order by tickets_sold desc
limit 5;

select
  u.username,
  u.full_name,
  count(b.booking_id) as booking_count
from users u
left join bookings b on b.user_id = u.user_id
group by u.username, u.full_name
order by booking_count desc;

select
  s.schedule_id,
  f.flight_no,
  a.seat_capacity,
  count(t.ticket_id) as sold_seats,
  round( (count(t.ticket_id)::numeric / a.seat_capacity) * 100, 2 ) as occupancy_percent
from flight_schedules s
join flights f on f.flight_id = s.flight_id
join aircraft a on a.aircraft_id = s.aircraft_id
left join bookings b on b.schedule_id = s.schedule_id
left join tickets t on t.booking_id = b.booking_id
group by s.schedule_id, f.flight_no, a.seat_capacity
order by occupancy_percent desc;

select
  f.flight_no,
  round(avg(t.ticket_price),2) as avg_ticket_price
from tickets t
join bookings b on b.booking_id = t.booking_id
join flight_schedules s on s.schedule_id = b.schedule_id
join flights f on f.flight_id = s.flight_id
group by f.flight_no
order by avg_ticket_price desc;
