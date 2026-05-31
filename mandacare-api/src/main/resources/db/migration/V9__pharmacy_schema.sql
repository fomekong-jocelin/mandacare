CREATE TABLE pharmacy_items (
    id UUID PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    label VARCHAR(100) NOT NULL,
    dosage VARCHAR(50),
    price DECIMAL(10, 2) NOT NULL,
    stock_quantity INT NOT NULL DEFAULT 0,
    alert_threshold INT NOT NULL DEFAULT 5
);

CREATE TABLE stock_movements (
    id UUID PRIMARY KEY,
    pharmacy_item_id UUID NOT NULL REFERENCES pharmacy_items(id) ON DELETE CASCADE,
    type VARCHAR(10) NOT NULL, -- 'IN' ou 'OUT'
    quantity INT NOT NULL,
    reason VARCHAR(255),
    created_at TIMESTAMP NOT NULL,
    user_id UUID -- Optionnel : ID de l'utilisateur qui a fait l'action
);

-- Insérer quelques médicaments de départ pour les tests
INSERT INTO pharmacy_items (id, code, label, dosage, price, stock_quantity, alert_threshold) VALUES
('a0e0a0e0-0000-0000-0000-000000000001', 'PARACET500', 'Paracétamol', '500mg', 500.00, 50, 10),
('a0e0a0e0-0000-0000-0000-000000000002', 'AMOXICILLIN', 'Amoxicilline', '1g', 1500.00, 3, 5), -- en dessous du seuil critique
('a0e0a0e0-0000-0000-0000-000000000003', 'IBUPROFEN', 'Ibuprofène', '400mg', 800.00, 20, 5);
