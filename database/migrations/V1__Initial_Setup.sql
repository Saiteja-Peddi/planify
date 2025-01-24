USE planify_dev;

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

-- Create Users Table
CREATE TABLE Users (
    UserID CHAR(36) PRIMARY KEY DEFAULT (UUID()),      -- Use UUID for globally unique UserID
    TenantID CHAR(36) NOT NULL,                        -- Tenant foreign key as UUID
    Name VARCHAR(255) NOT NULL,
    Email VARCHAR(255) NOT NULL UNIQUE,
    Role ENUM('Admin', 'Member', 'Manager', 'Viewer', 'Contributor') NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    IsActive BOOLEAN DEFAULT TRUE,
    PhoneNumber VARCHAR(20),
    Address TEXT,
    FOREIGN KEY (TenantID) REFERENCES Tenants(TenantID) ON DELETE CASCADE,
    INDEX (TenantID)                                   -- Index for filtering by TenantID
);

-- Create Projects Table
CREATE TABLE Projects (
    ProjectID CHAR(36) PRIMARY KEY DEFAULT (UUID()),   -- Use UUID for globally unique ProjectID
    TenantID CHAR(36) NOT NULL,                        -- Tenant foreign key as UUID
    Name VARCHAR(255) NOT NULL,
    Description TEXT,
    StartDate DATE,
    EndDate DATE,
    Status ENUM('Active', 'Completed', 'OnHold') DEFAULT 'Active',
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Budget DECIMAL(10, 2),
    FinancialDetails TEXT,
    FOREIGN KEY (TenantID) REFERENCES Tenants(TenantID) ON DELETE CASCADE,
    INDEX (TenantID)                                   -- Index for filtering by TenantID
);

-- Create Tasks Table
CREATE TABLE Tasks (
    TaskID CHAR(36) PRIMARY KEY DEFAULT (UUID()),      -- Unique identifier for each task
    TenantID CHAR(36) NOT NULL,                        -- Tenant foreign key
    ProjectID CHAR(36) NOT NULL,                       -- Project foreign key
    ParentTaskID CHAR(36),                             -- Reference to a parent task (optional)
    Title VARCHAR(255) NOT NULL,                       -- Title of the task
    Description TEXT,                                  -- Detailed description of the task
    Status ENUM('Open', 'InProgress', 'Closed', 'Pending', 'Completed') DEFAULT 'Open',  -- Unified statuses
    Priority ENUM('Low', 'Medium', 'High') DEFAULT 'Medium',  -- Priority of the task
    CreatedBy CHAR(36),                                -- User who created the task
    AssignedTo CHAR(36),                               -- User to whom the task is assigned
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,     -- Task creation timestamp
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,  -- Task update timestamp
    DueDate DATE,
    Attachments JSON,
    FOREIGN KEY (TenantID) REFERENCES Tenants(TenantID) ON DELETE CASCADE,      -- Tenant association
    FOREIGN KEY (ProjectID) REFERENCES Projects(ProjectID) ON DELETE CASCADE,  -- Project association
    FOREIGN KEY (ParentTaskID) REFERENCES Tasks(TaskID) ON DELETE SET NULL,     -- Optional parent task
    FOREIGN KEY (CreatedBy) REFERENCES Users(UserID) ON DELETE SET NULL,        -- Creator reference
    FOREIGN KEY (AssignedTo) REFERENCES Users(UserID) ON DELETE SET NULL,       -- Assignee reference
    INDEX (TenantID),                                  -- Index for filtering by TenantID
    INDEX (ProjectID)                                 -- Index for filtering by ProjectID
);

-- Create UserProjects Table
CREATE TABLE UserProjects (
    UserID CHAR(36) NOT NULL,                         -- User foreign key
    ProjectID CHAR(36) NOT NULL,                      -- Project foreign key
    RoleInProject ENUM('Admin', 'Member', 'Manager', 'Viewer', 'Contributor') DEFAULT 'Member',
    PRIMARY KEY (UserID, ProjectID),                  -- Composite primary key
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE CASCADE,
    FOREIGN KEY (ProjectID) REFERENCES Projects(ProjectID) ON DELETE CASCADE,
    INDEX (UserID)                                    -- Index for filtering by UserID
);

-- Create Comments Table
CREATE TABLE Comments (
    CommentID CHAR(36) PRIMARY KEY DEFAULT (UUID()),  -- Unique identifier for each comment
    TenantID CHAR(36) NOT NULL,                        -- Tenant foreign key
    TaskID CHAR(36) NOT NULL,                         -- Task foreign key
    UserID CHAR(36),                                  -- User foreign key
    Content TEXT NOT NULL,                            -- Content of the comment
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- Comment creation timestamp
    Attachments JSON,
    FOREIGN KEY (TenantID) REFERENCES Tenants(TenantID) ON DELETE CASCADE,  -- Tenant association
    FOREIGN KEY (TaskID) REFERENCES Tasks(TaskID) ON DELETE CASCADE,  -- Task association
    FOREIGN KEY (UserID) REFERENCES Users(UserID) ON DELETE SET NULL,  -- User association
    INDEX (TaskID)                                   -- Index for filtering by TaskID
);

-- Create Plans Table
CREATE TABLE Plans (
    PlanID CHAR(36) PRIMARY KEY DEFAULT (UUID()),      -- Unique identifier for the plan
    Name VARCHAR(255) NOT NULL,                       -- Plan name (e.g., Free, Premium, Enterprise)
    Price DECIMAL(10, 2) NOT NULL,                    -- Monthly or yearly price
    BillingCycle ENUM('Monthly', 'Yearly') DEFAULT 'Monthly', -- Billing frequency
    Features JSON,                                    -- JSON object storing features or limits
    MaxProjects INT,                                  -- Maximum number of projects allowed
    MaxTasks INT,                                     -- Maximum number of tasks allowed
    MaxUsers INT,                                     -- Maximum number of users allowed
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    Discounts JSON
);

-- Create TenantSubscriptions Table
CREATE TABLE TenantSubscriptions (
    SubscriptionID CHAR(36) PRIMARY KEY DEFAULT (UUID()),  -- Unique subscription identifier
    TenantID CHAR(36) NOT NULL,                           -- Reference to the tenant
    PlanID CHAR(36) NOT NULL,                             -- Reference to the subscription plan
    StartDate DATE NOT NULL,                              -- Subscription start date
    EndDate DATE,                                         -- Subscription end date (null if active)
    Status ENUM('Active', 'Expired', 'Cancelled') DEFAULT 'Active',  -- Subscription status
    AutoRenew BOOLEAN DEFAULT TRUE,                      -- Auto-renewal flag
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (TenantID) REFERENCES Tenants(TenantID) ON DELETE CASCADE,
    FOREIGN KEY (PlanID) REFERENCES Plans(PlanID) ON DELETE CASCADE,
    INDEX (TenantID)                                    -- Index for filtering by TenantID
);

-- Create Payments Table
CREATE TABLE Payments (
    PaymentID CHAR(36) PRIMARY KEY DEFAULT (UUID()),      -- Unique identifier for the payment
    TenantID CHAR(36) NOT NULL,                           -- Reference to the tenant
    SubscriptionID CHAR(36) NOT NULL,                     -- Reference to the subscription
    Amount DECIMAL(10, 2) NOT NULL,                       -- Payment amount
    Currency VARCHAR(10) DEFAULT 'USD',                   -- Currency
    TransactionID VARCHAR(255) NOT NULL,                  -- Payment gateway transaction ID
    Status ENUM('Success', 'Failed', 'Pending') DEFAULT 'Pending', -- Payment status
    PaymentDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,      -- Payment timestamp
    PaymentMethod ENUM('CreditCard', 'PayPal', 'BankTransfer') NOT NULL,
    Token VARCHAR(255),                                   -- Tokenized payment information
    FOREIGN KEY (TenantID) REFERENCES Tenants(TenantID) ON DELETE CASCADE,
    FOREIGN KEY (SubscriptionID) REFERENCES TenantSubscriptions(SubscriptionID) ON DELETE CASCADE,
    INDEX (TenantID)                                      -- Index for filtering by TenantID
);

-- Create UsageTracking Table
CREATE TABLE UsageTracking (
    TenantID CHAR(36) PRIMARY KEY,                      -- Reference to the tenant
    ProjectsCreated INT DEFAULT 0,                     -- Number of projects created
    TasksCreated INT DEFAULT 0,                        -- Number of tasks created
    UsersAdded INT DEFAULT 0,                          -- Number of users added
    ApiCalls INT DEFAULT 0,
    StorageUsage DECIMAL(10, 2) DEFAULT 0.0,
    LastUpdated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (TenantID) REFERENCES Tenants(TenantID) ON DELETE CASCADE
);