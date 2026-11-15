-- +goose Up
-- all times are stored in UTC

create table users (
  id          bigserial primary key,
  auth0_sub   text not null unique,       -- subject from the Auth0 token
  email       text,
  created_at  timestamptz not null default now()
);

create table inputs (
  id           bigserial primary key,
  user_id      bigint not null references users(id),
  name         text not null,
  description  text,
  attrs        jsonb not null default '{}',
  created_at   timestamptz not null default now(),
  unique (user_id, name)
);

create table outputs (
  id           bigserial primary key,
  user_id      bigint not null references users(id),
  name         text not null,
  description  text,
  attrs        jsonb not null default '{}',
  created_at   timestamptz not null default now(),
  unique (user_id, name)
);

create table events (
  id           bigserial primary key,
  user_id      bigint not null references users(id),
  started_at   timestamptz not null,
  ended_at     timestamptz,                -- null: instant or still ongoing
  text         text not null,              -- what was said, as said
  recorded_at  timestamptz not null default now()
);

-- intermediary tables

create table event_inputs (
  event_id  bigint not null references events(id),
  input_id  bigint not null references inputs(id),
  detail    text,                          -- very ripe, more than usual
  attrs     jsonb not null default '{}',   -- this occurrence: {"ripeness": "very ripe"}
  primary key (event_id, input_id)
);

create table event_outputs (
  event_id   bigint not null references events(id),
  output_id  bigint not null references outputs(id),
  detail     text,                         -- mild, worse than yesterday
  attrs      jsonb not null default '{}',  -- this occurrence: {"bristol": 6}
  primary key (event_id, output_id)
);

create table input_components (
  input_id      bigint not null references inputs(id),
  component_id  bigint not null references inputs(id),
  primary key (input_id, component_id)
);

create index on events (user_id, started_at);
create index on event_inputs (input_id);
create index on event_outputs (output_id);
create index on input_components (component_id);

-- +goose Down
drop table input_components, event_outputs, event_inputs, events, outputs, inputs, users;
