CREATE TABLE notes (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    body text NOT NULL
);
