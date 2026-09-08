-- cairn-exempt(widgets)
-- No reason given. An exemption without a reason is indistinguishable from an
-- oversight, so the guard must not honour it.
CREATE TABLE widgets (
    id uuid PRIMARY KEY,
    label text NOT NULL
);
