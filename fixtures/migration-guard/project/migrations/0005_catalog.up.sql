-- cairn-exempt(plan_catalog): platform-plane catalogue, shared by every tenant
-- and read-only to the application. It carries no tenant column by design.
CREATE TABLE plan_catalog (
    code text PRIMARY KEY,
    monthly_cents bigint NOT NULL
);
