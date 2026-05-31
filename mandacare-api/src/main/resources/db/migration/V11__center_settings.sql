CREATE TABLE center_settings (
    id SMALLINT PRIMARY KEY CHECK (id = 1),
    name VARCHAR(150) NOT NULL,
    slogan VARCHAR(200) NOT NULL,
    phone VARCHAR(40),
    email VARCHAR(120),
    city VARCHAR(100) NOT NULL,
    address VARCHAR(200),
    po_box VARCHAR(60),
    rccm VARCHAR(80),
    taxpayer_number VARCHAR(80),
    updated_at TIMESTAMP NOT NULL
);

INSERT INTO center_settings (
    id,
    name,
    slogan,
    phone,
    email,
    city,
    address,
    po_box,
    rccm,
    taxpayer_number,
    updated_at
)
VALUES (
    1,
    'Cabinet de Soins Manda Nsappe',
    'Soigner mieux, gérer simplement.',
    '+237 691 501 780',
    NULL,
    'Logbessou',
    'Logbessou, Douala',
    NULL,
    NULL,
    NULL,
    CURRENT_TIMESTAMP
);
