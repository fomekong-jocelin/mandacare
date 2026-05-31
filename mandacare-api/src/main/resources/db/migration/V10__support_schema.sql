CREATE TABLE support_tickets (
    id UUID PRIMARY KEY,
    subject VARCHAR(150) NOT NULL,
    description TEXT NOT NULL,
    category VARCHAR(50) NOT NULL, -- 'BUG', 'QUESTION', 'REQUEST'
    priority VARCHAR(20) NOT NULL, -- 'LOW', 'MEDIUM', 'HIGH', 'URGENT'
    status VARCHAR(20) NOT NULL DEFAULT 'OPEN', -- 'OPEN', 'RESOLVED'
    created_at TIMESTAMP NOT NULL,
    user_id UUID NOT NULL REFERENCES auth_users(id) ON DELETE CASCADE
);
