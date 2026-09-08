CREATE TABLE events (
    id bigserial PRIMARY KEY,
    payload jsonb NOT NULL
);
