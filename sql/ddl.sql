drop table if exists payments cascade;
drop table if exists tickets cascade;
drop table if exists bookings cascade;
drop table if exists flight_schedules cascade;
drop table if exists flights cascade;
drop table if exists aircraft cascade;
drop table if exists airports cascade;
drop table if exists user_roles cascade;
drop table if exists roles cascade;
drop table if exists users cascade;

create table users (
  user_id        bigserial primary key,
  username       varchar(50) not null unique,
  email          varchar(120) not null unique,
  password_hash  text not null,
  full_name      varchar(120) not null,
  phone          varchar(30),
  is_active      boolean not null default true,
  created_at     timestamptz not null default now()
);

create table roles (
  role_id     bigserial primary key,
  role_name   varchar(40) not null unique,
  description text,
  created_at  timestamptz not null default now()
);

create table user_roles (
  user_id   bigint not null references users(user_id) on delete cascade,
  role_id   bigint not null references roles(role_id) on delete cascade,
  assigned_at timestamptz not null default now(),
  primary key (user_id, role_id)
);

create table airports (
  airport_id   bigserial primary key,
  iata_code    char(3) not null unique,
  name         varchar(120) not null,
  city         varchar(80) not null,
  country      varchar(80) not null,
  created_at   timestamptz not null default now()
);

create table aircraft (
  aircraft_id     bigserial primary key,
  tail_number     varchar(20) not null unique,
  model           varchar(80) not null,
  manufacturer    varchar(80) not null,
  seat_capacity   int not null check (seat_capacity > 0),
  created_at      timestamptz not null default now()
);

create table flights (
  flight_id         bigserial primary key,
  flight_no         varchar(10) not null unique,
  from_airport_id   bigint not null references airports(airport_id),
  to_airport_id     bigint not null references airports(airport_id),
  base_price        numeric(10,2) not null check (base_price >= 0),
  created_at        timestamptz not null default now(),
  constraint chk_route_not_same check (from_airport_id <> to_airport_id)
);

create table flight_schedules (
  schedule_id        bigserial primary key,
  flight_id          bigint not null references flights(flight_id) on delete cascade,
  aircraft_id        bigint not null references aircraft(aircraft_id),
  depart_at          timestamptz not null,
  arrive_at          timestamptz not null,
  status             varchar(20) not null default 'SCHEDULED'
                     check (status in ('SCHEDULED','DELAYED','CANCELLED','COMPLETED')),
  gate               varchar(10),
  created_at         timestamptz not null default now(),
  constraint chk_arrive_after_depart check (arrive_at > depart_at)
);

create index idx_schedules_flight on flight_schedules(flight_id);
create index idx_schedules_aircraft on flight_schedules(aircraft_id);

create table bookings (
  booking_id     bigserial primary key,
  user_id        bigint not null references users(user_id),
  schedule_id    bigint not null references flight_schedules(schedule_id) on delete cascade,
  booking_ref    varchar(12) not null unique,
  status         varchar(20) not null default 'PENDING'
                 check (status in ('PENDING','CONFIRMED','CANCELLED')),
  booked_at      timestamptz not null default now()
);

create index idx_bookings_user on bookings(user_id);
create index idx_bookings_schedule on bookings(schedule_id);

create table tickets (
  ticket_id        bigserial primary key,
  booking_id       bigint not null references bookings(booking_id) on delete cascade,
  passenger_name   varchar(120) not null,
  passport_no      varchar(30),
  seat_no          varchar(5) not null,
  ticket_price     numeric(10,2) not null check (ticket_price >= 0),
  issued_at        timestamptz not null default now()
);

create index idx_tickets_booking on tickets(booking_id);

create table payments (
  payment_id     bigserial primary key,
  booking_id     bigint not null references bookings(booking_id) on delete cascade,
  amount         numeric(10,2) not null check (amount >= 0),
  method         varchar(20) not null check (method in ('CARD','CASH','TRANSFER')),
  paid_at        timestamptz not null default now()
);

create index idx_payments_booking on payments(booking_id);
