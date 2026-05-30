CREATE TABLE IF NOT EXISTS visit_lab_results (
    id UUID PRIMARY KEY,
    patient_id UUID NOT NULL REFERENCES patients(id),
    visit_id UUID NOT NULL REFERENCES visits(id),
    result_number VARCHAR(60) NOT NULL UNIQUE,
    dossier_number VARCHAR(60),
    exam_type VARCHAR(180) NOT NULL,
    results TEXT,
    observations TEXT,
    sample_date DATE,
    normal_results BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(40) NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL,
    validated_at TIMESTAMP WITH TIME ZONE NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_visit_lab_results_visit
    ON visit_lab_results(visit_id, created_at DESC);
