CREATE TABLE invoices (
    id uuid PRIMARY KEY,
    tenant_id uuid NOT NULL,
    amount_cents bigint NOT NULL
);
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
CREATE POLICY tenant_isolation ON invoices USING (tenant_id = current_setting('app.tenant')::uuid);
