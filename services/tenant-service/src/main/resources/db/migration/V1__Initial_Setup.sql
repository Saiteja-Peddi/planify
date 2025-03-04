USE tenant_db;

-- Create Tenants Table
CREATE TABLE Tenants (
    TenantID CHAR(36) PRIMARY KEY DEFAULT (UUID()),    -- Use UUID for globally unique TenantID
    Name VARCHAR(255) NOT NULL,
    AdminEmail VARCHAR(255) NOT NULL UNIQUE,
    PlanType ENUM('free', 'premium', 'enterprise') NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    IsActive BOOLEAN DEFAULT TRUE,
    PhoneNumber VARCHAR(20),
    Address TEXT
);