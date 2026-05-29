CREATE TABLE IF NOT EXISTS roles (
    id UUID PRIMARY KEY,
    code VARCHAR(40) NOT NULL UNIQUE,
    label VARCHAR(120) NOT NULL,
    description TEXT
);

CREATE TABLE IF NOT EXISTS auth_users (
    id UUID PRIMARY KEY,
    role_id UUID NOT NULL REFERENCES roles(id),
    first_name VARCHAR(120) NOT NULL,
    last_name VARCHAR(120) NOT NULL,
    phone VARCHAR(40) NOT NULL UNIQUE,
    email VARCHAR(180) UNIQUE,
    username VARCHAR(80) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(30) NOT NULL,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS patients (
    id UUID PRIMARY KEY,
    patient_number VARCHAR(40) NOT NULL UNIQUE,
    first_name VARCHAR(120) NOT NULL,
    last_name VARCHAR(120) NOT NULL,
    sex VARCHAR(20) NOT NULL,
    birth_date DATE,
    declared_age INTEGER,
    phone VARCHAR(40),
    whatsapp_phone VARCHAR(40),
    district VARCHAR(120),
    city VARCHAR(120),
    profession VARCHAR(120),
    emergency_contact_name VARCHAR(180),
    emergency_contact_phone VARCHAR(40),
    blood_group VARCHAR(10),
    allergies TEXT,
    medical_history TEXT,
    surgical_history TEXT,
    family_history TEXT,
    digital_consent BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_patients_name ON patients(last_name, first_name);
CREATE INDEX IF NOT EXISTS idx_patients_phone ON patients(phone);

CREATE TABLE IF NOT EXISTS visits (
    id UUID PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id),
    reason TEXT NOT NULL,
    target_service VARCHAR(120),
    status VARCHAR(40) NOT NULL,
    priority VARCHAR(30) NOT NULL,
    arrival_at TIMESTAMP WITH TIME ZONE NOT NULL,
    closed_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES auth_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_visits_today ON visits(arrival_at, status);

CREATE TABLE IF NOT EXISTS vitals (
    id UUID PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id),
    visit_id UUID NOT NULL REFERENCES visits(id),
    temperature NUMERIC(4,1),
    systolic_pressure INTEGER,
    diastolic_pressure INTEGER,
    pulse INTEGER,
    respiratory_rate INTEGER,
    oxygen_saturation INTEGER,
    weight NUMERIC(5,2),
    height NUMERIC(5,2),
    bmi NUMERIC(5,2),
    blood_glucose NUMERIC(5,2),
    created_by UUID REFERENCES auth_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE IF NOT EXISTS consultations (
    id UUID PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id),
    visit_id UUID NOT NULL REFERENCES visits(id),
    doctor_id UUID REFERENCES auth_users(id),
    reason TEXT NOT NULL,
    symptoms TEXT,
    clinical_exam TEXT,
    provisional_diagnosis TEXT,
    final_diagnosis TEXT,
    advice TEXT,
    confidential_notes TEXT,
    status VARCHAR(40) NOT NULL,
    decision VARCHAR(40) NOT NULL DEFAULT 'KEEP_IN_CONSULTATION',
    validated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

ALTER TABLE consultations
    ADD COLUMN IF NOT EXISTS decision VARCHAR(40) NOT NULL DEFAULT 'KEEP_IN_CONSULTATION';

CREATE TABLE IF NOT EXISTS prescriptions (
    id UUID PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id),
    consultation_id UUID NOT NULL REFERENCES consultations(id),
    prescription_number VARCHAR(40) NOT NULL UNIQUE,
    prescripteur_id UUID REFERENCES auth_users(id),
    status VARCHAR(40) NOT NULL,
    pdf_url TEXT,
    qr_code TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    validated_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE IF NOT EXISTS prescription_items (
    id UUID PRIMARY KEY,
    prescription_id UUID NOT NULL REFERENCES prescriptions(id),
    drug_name VARCHAR(180) NOT NULL,
    form VARCHAR(80),
    dosage VARCHAR(120),
    frequency VARCHAR(120),
    duration VARCHAR(120),
    quantity INTEGER,
    instructions TEXT
);

CREATE TABLE IF NOT EXISTS audit_logs (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth_users(id),
    action VARCHAR(80) NOT NULL,
    module VARCHAR(80) NOT NULL,
    entity_type VARCHAR(80),
    entity_id UUID,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);
