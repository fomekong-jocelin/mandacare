CREATE TABLE roles (
    id UUID PRIMARY KEY,
    code VARCHAR(40) NOT NULL UNIQUE,
    label VARCHAR(120) NOT NULL,
    description TEXT
);

CREATE TABLE permissions (
    id UUID PRIMARY KEY,
    role_id UUID NOT NULL REFERENCES roles(id),
    module VARCHAR(80) NOT NULL,
    action VARCHAR(40) NOT NULL,
    UNIQUE (role_id, module, action)
);

CREATE TABLE auth_users (
    id UUID PRIMARY KEY,
    role_id UUID NOT NULL REFERENCES roles(id),
    first_name VARCHAR(120) NOT NULL,
    last_name VARCHAR(120) NOT NULL,
    phone VARCHAR(40),
    email VARCHAR(180),
    username VARCHAR(80) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    status VARCHAR(30) NOT NULL,
    last_login_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE patients (
    id UUID PRIMARY KEY,
    patient_number VARCHAR(40) NOT NULL UNIQUE,
    first_name VARCHAR(120) NOT NULL,
    last_name VARCHAR(120) NOT NULL,
    sex VARCHAR(20) NOT NULL,
    birth_date DATE,
    declared_age INTEGER,
    phone VARCHAR(40) NOT NULL,
    whatsapp_phone VARCHAR(40),
    district VARCHAR(120),
    city VARCHAR(120),
    profession VARCHAR(120),
    emergency_contact_name VARCHAR(180),
    emergency_contact_phone VARCHAR(40),
    blood_group VARCHAR(20),
    allergies TEXT,
    medical_history TEXT,
    surgical_history TEXT,
    family_history TEXT,
    digital_consent BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_patients_name ON patients(last_name, first_name);
CREATE INDEX idx_patients_phone ON patients(phone);

CREATE TABLE visits (
    id UUID PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id),
    reason TEXT NOT NULL,
    target_service VARCHAR(40) NOT NULL,
    status VARCHAR(40) NOT NULL,
    priority VARCHAR(30) NOT NULL,
    arrival_at TIMESTAMP WITH TIME ZONE NOT NULL,
    closed_at TIMESTAMP WITH TIME ZONE,
    created_by UUID REFERENCES auth_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX idx_visits_today ON visits(arrival_at, status);

CREATE TABLE vitals (
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
    blood_glucose NUMERIC(6,2),
    created_by UUID REFERENCES auth_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE consultations (
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
    validated_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE exams (
    id UUID PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    name VARCHAR(180) NOT NULL,
    category VARCHAR(120),
    price NUMERIC(12,2) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE exam_requests (
    id UUID PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id),
    consultation_id UUID REFERENCES consultations(id),
    request_number VARCHAR(60) NOT NULL UNIQUE,
    status VARCHAR(40) NOT NULL,
    priority VARCHAR(30) NOT NULL,
    created_by UUID REFERENCES auth_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE exam_request_lines (
    id UUID PRIMARY KEY,
    exam_request_id UUID NOT NULL REFERENCES exam_requests(id),
    exam_id UUID NOT NULL REFERENCES exams(id),
    price NUMERIC(12,2) NOT NULL,
    comment TEXT
);

CREATE TABLE lab_results (
    id UUID PRIMARY KEY,
    exam_request_id UUID NOT NULL REFERENCES exam_requests(id),
    result_number VARCHAR(60) NOT NULL UNIQUE,
    status VARCHAR(40) NOT NULL,
    conclusion TEXT,
    validated_by UUID REFERENCES auth_users(id),
    validated_at TIMESTAMP WITH TIME ZONE,
    pdf_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE benefits (
    id UUID PRIMARY KEY,
    code VARCHAR(60) NOT NULL UNIQUE,
    name VARCHAR(180) NOT NULL,
    category VARCHAR(120),
    price NUMERIC(12,2) NOT NULL,
    active BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE invoices (
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

CREATE TABLE payments (
    id UUID PRIMARY KEY,
    invoice_id UUID NOT NULL REFERENCES invoices(id),
    amount NUMERIC(12,2) NOT NULL,
    mode VARCHAR(40) NOT NULL,
    reference VARCHAR(120),
    status VARCHAR(40) NOT NULL,
    created_by UUID REFERENCES auth_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE documents (
    id UUID PRIMARY KEY,
    patient_id UUID REFERENCES patients(id),
    type VARCHAR(60) NOT NULL,
    source_id UUID,
    title VARCHAR(180) NOT NULL,
    pdf_url TEXT NOT NULL,
    status VARCHAR(40) NOT NULL,
    created_by UUID REFERENCES auth_users(id),
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE TABLE audit_logs (
    id UUID PRIMARY KEY,
    user_id UUID REFERENCES auth_users(id),
    action VARCHAR(80) NOT NULL,
    module VARCHAR(80) NOT NULL,
    entity_type VARCHAR(80),
    entity_id UUID,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL
);

