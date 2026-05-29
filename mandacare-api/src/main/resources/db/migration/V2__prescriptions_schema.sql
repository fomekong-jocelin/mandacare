CREATE TABLE prescriptions (
    id UUID PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id),
    consultation_id UUID NOT NULL REFERENCES consultations(id),
    prescription_number VARCHAR(60) NOT NULL UNIQUE,
    prescripteur_id UUID REFERENCES auth_users(id),
    status VARCHAR(40) NOT NULL,
    pdf_url TEXT,
    qr_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    validated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE prescription_items (
    id UUID PRIMARY KEY,
    prescription_id UUID NOT NULL REFERENCES prescriptions(id),
    drug_name VARCHAR(255) NOT NULL,
    form VARCHAR(120),
    dosage VARCHAR(120),
    frequency VARCHAR(120),
    duration VARCHAR(120),
    quantity INTEGER,
    instructions TEXT
);
