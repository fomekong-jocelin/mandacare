CREATE TABLE IF NOT EXISTS invoices (
    id UUID PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id),
    visit_id UUID REFERENCES visits(id),
    invoice_number VARCHAR(60) NOT NULL UNIQUE,
    total_amount NUMERIC(12,2) NOT NULL,
    discount NUMERIC(12,2) NOT NULL DEFAULT 0,
    net_amount NUMERIC(12,2) NOT NULL,
    paid_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    remaining_amount NUMERIC(12,2) NOT NULL,
    status VARCHAR(40) NOT NULL,
    created_by UUID REFERENCES auth_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS payments (
    id UUID PRIMARY KEY,
    invoice_id UUID NOT NULL REFERENCES invoices(id),
    amount NUMERIC(12,2) NOT NULL,
    mode VARCHAR(40) NOT NULL,
    reference VARCHAR(120),
    status VARCHAR(40) NOT NULL,
    created_by UUID REFERENCES auth_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);
