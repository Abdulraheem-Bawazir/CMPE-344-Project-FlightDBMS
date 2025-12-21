insert into roles(role_name, description) values
('admin','Full access'),
('employee','Manage flights/schedules'),
('customer','Book flights'),
('technical','Maintenance/support');

insert into users(username,email,password_hash,full_name,phone) values
('admin','admin@flightdbms.com','demo_hash','Admin User','+90-000-000-0000'),
('emp1','emp1@flightdbms.com','demo_hash','Employee One','+90-111-111-1111'),
('tech1','tech1@flightdbms.com','demo_hash','Tech Staff','+90-222-222-2222'),
('cust1','cust1@flightdbms.com','demo_hash','Customer One','+90-333-333-3333'),
('cust2','cust2@flightdbms.com','demo_hash','Customer Two','+90-444-444-4444');

insert into user_roles(user_id, role_id)
select u.user_id, r.role_id from users u join roles r on r.role_name='admin' where u.username='admin';

insert into user_roles(user_id, role_id)
select u.user_id, r.role_id from users u join roles r on r.role_name='employee' where u.username='emp1';

insert into user_roles(user_id, role_id)
select u.user_id, r.role_id from users u join roles r on r.role_name='technical' where u.username='tech1';

insert into user_roles(user_id, role_id)
select u.user_id, r.role_id from users u join roles r on r.role_name='customer' where u.username in ('cust1','cust2');

insert into airports(iata_code,name,city,country) values
('ECN','Ercan International Airport','Nicosia','Cyprus'),
('IST','Istanbul Airport','Istanbul','Türkiye'),
('SAW','Sabiha Gökçen Airport','Istanbul','Türkiye'),
('LHR','Heathrow Airport','London','UK'),
('DXB','Dubai International Airport','Dubai','UAE');

insert into aircraft(tail_number,model,manufacturer,seat_capacity) values
('TC-AAA','A320','Airbus',180),
('TC-BBB','B737-800','Boeing',189),
('TC-CCC','A321','Airbus',220);

insert into flights(flight_no,from_airport_id,to_airport_id,base_price)
select 'CY101', a1.airport_id, a2.airport_id, 120
from airports a1, airports a2 where a1.iata_code='ECN' and a2.iata_code='IST';

insert into flights(flight_no,from_airport_id,to_airport_id,base_price)
select 'CY102', a1.airport_id, a2.airport_id, 95
from airports a1, airports a2 where a1.iata_code='IST' and a2.iata_code='ECN';

insert into flights(flight_no,from_airport_id,to_airport_id,base_price)
select 'TR201', a1.airport_id, a2.airport_id, 80
from airports a1, airports a2 where a1.iata_code='SAW' and a2.iata_code='IST';

insert into flights(flight_no,from_airport_id,to_airport_id,base_price)
select 'UK301', a1.airport_id, a2.airport_id, 250
from airports a1, airports a2 where a1.iata_code='IST' and a2.iata_code='LHR';

insert into flights(flight_no,from_airport_id,to_airport_id,base_price)
select 'AE401', a1.airport_id, a2.airport_id, 220
from airports a1, airports a2 where a1.iata_code='IST' and a2.iata_code='DXB';

insert into flight_schedules(flight_id,aircraft_id,depart_at,arrive_at,status,gate)
select f.flight_id, ac.aircraft_id, now() + interval '1 day', now() + interval '1 day 1 hour 20 min', 'SCHEDULED','A1'
from flights f join aircraft ac on ac.tail_number='TC-AAA' where f.flight_no='CY101';

insert into flight_schedules(flight_id,aircraft_id,depart_at,arrive_at,status,gate)
select f.flight_id, ac.aircraft_id, now() + interval '2 day', now() + interval '2 day 1 hour 15 min', 'SCHEDULED','B2'
from flights f join aircraft ac on ac.tail_number='TC-BBB' where f.flight_no='CY102';

insert into flight_schedules(flight_id,aircraft_id,depart_at,arrive_at,status,gate)
select f.flight_id, ac.aircraft_id, now() + interval '1 day 3 hour', now() + interval '1 day 3 hour 45 min', 'DELAYED','C3'
from flights f join aircraft ac on ac.tail_number='TC-CCC' where f.flight_no='TR201';

insert into flight_schedules(flight_id,aircraft_id,depart_at,arrive_at,status,gate)
select f.flight_id, ac.aircraft_id, now() + interval '3 day', now() + interval '3 day 4 hour', 'SCHEDULED','D4'
from flights f join aircraft ac on ac.tail_number='TC-AAA' where f.flight_no='UK301';

insert into flight_schedules(flight_id,aircraft_id,depart_at,arrive_at,status,gate)
select f.flight_id, ac.aircraft_id, now() + interval '4 day', now() + interval '4 day 3 hour 30 min', 'SCHEDULED','E5'
from flights f join aircraft ac on ac.tail_number='TC-BBB' where f.flight_no='AE401';

insert into bookings(user_id, schedule_id, booking_ref, status)
select u.user_id, s.schedule_id, '', 'PENDING'
from users u, flight_schedules s, flights f
where u.username='cust1' and s.flight_id=f.flight_id and f.flight_no='CY101'
limit 1;

insert into bookings(user_id, schedule_id, booking_ref, status)
select u.user_id, s.schedule_id, '', 'PENDING'
from users u, flight_schedules s, flights f
where u.username='cust2' and s.flight_id=f.flight_id and f.flight_no='CY101'
limit 1;

insert into bookings(user_id, schedule_id, booking_ref, status)
select u.user_id, s.schedule_id, '', 'PENDING'
from users u, flight_schedules s, flights f
where u.username='cust1' and s.flight_id=f.flight_id and f.flight_no='CY102'
limit 1;

insert into bookings(user_id, schedule_id, booking_ref, status)
select u.user_id, s.schedule_id, '', 'PENDING'
from users u, flight_schedules s, flights f
where u.username='cust2' and s.flight_id=f.flight_id and f.flight_no='UK301'
limit 1;

insert into bookings(user_id, schedule_id, booking_ref, status)
select u.user_id, s.schedule_id, '', 'PENDING'
from users u, flight_schedules s, flights f
where u.username='cust1' and s.flight_id=f.flight_id and f.flight_no='AE401'
limit 1;

insert into tickets(booking_id,passenger_name,passport_no,seat_no,ticket_price)
select b.booking_id,'Customer One','P12345','12A',140 from bookings b limit 1;

insert into tickets(booking_id,passenger_name,passport_no,seat_no,ticket_price)
select b.booking_id,'Customer Two','P23456','12B',140 from bookings b offset 1 limit 1;

insert into tickets(booking_id,passenger_name,passport_no,seat_no,ticket_price)
select b.booking_id,'Customer One','P12345','14C',110 from bookings b offset 2 limit 1;

insert into tickets(booking_id,passenger_name,passport_no,seat_no,ticket_price)
select b.booking_id,'Customer Two','P23456','2D',260 from bookings b offset 3 limit 1;

insert into tickets(booking_id,passenger_name,passport_no,seat_no,ticket_price)
select b.booking_id,'Customer One','P12345','8A',240 from bookings b offset 4 limit 1;

insert into payments(booking_id,amount,method)
select booking_id, ticket_price, 'CARD' from tickets limit 3;
