-- HR (human resources) schema for Turkish Text-to-SQL
-- Dialect: SQLite

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS performance_reviews;
DROP TABLE IF EXISTS leave_requests;
DROP TABLE IF EXISTS salaries;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS positions;
DROP TABLE IF EXISTS departments;

-- Company departments (e.g. 'Yazılım', 'Satış', 'Muhasebe')
CREATE TABLE departments (
    department_id  INTEGER PRIMARY KEY,
    name           TEXT NOT NULL UNIQUE,
    city           TEXT NOT NULL              -- office location, e.g. 'İstanbul', 'Ankara'
);

-- Job titles (e.g. 'Kıdemli Yazılım Mühendisi', 'Satış Uzmanı')
CREATE TABLE positions (
    position_id  INTEGER PRIMARY KEY,
    title        TEXT NOT NULL,
    level        TEXT NOT NULL CHECK (level IN ('stajyer', 'junior', 'mid', 'senior', 'yönetici'))
);

-- Employees; manager_id points to another employee
CREATE TABLE employees (
    employee_id      INTEGER PRIMARY KEY,
    first_name       TEXT NOT NULL,
    last_name        TEXT NOT NULL,
    email            TEXT NOT NULL UNIQUE,
    gender           TEXT,                        -- 'F', 'M' or NULL
    birth_date       TEXT,                        -- 'YYYY-MM-DD'
    hire_date        TEXT NOT NULL,               -- 'YYYY-MM-DD'
    termination_date TEXT,                        -- NULL if still employed
    employment_type  TEXT NOT NULL CHECK (employment_type IN ('tam zamanlı', 'yarı zamanlı', 'stajyer')),
    department_id    INTEGER NOT NULL,
    position_id      INTEGER NOT NULL,
    manager_id       INTEGER,                     -- NULL for top-level managers
    FOREIGN KEY (department_id) REFERENCES departments(department_id),
    FOREIGN KEY (position_id) REFERENCES positions(position_id),
    FOREIGN KEY (manager_id) REFERENCES employees(employee_id)
);

-- Salary history; the row with the latest start_date is the current salary
CREATE TABLE salaries (
    salary_id     INTEGER PRIMARY KEY,
    employee_id   INTEGER NOT NULL,
    gross_amount  REAL NOT NULL CHECK (gross_amount > 0),   -- monthly gross salary in TL
    start_date    TEXT NOT NULL,                            -- 'YYYY-MM-DD'
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Leave requests
CREATE TABLE leave_requests (
    leave_id     INTEGER PRIMARY KEY,
    employee_id  INTEGER NOT NULL,
    leave_type   TEXT NOT NULL CHECK (leave_type IN ('yıllık izin', 'hastalık izni', 'mazeret izni', 'ücretsiz izin')),
    start_date   TEXT NOT NULL,                  -- 'YYYY-MM-DD'
    end_date     TEXT NOT NULL,                  -- 'YYYY-MM-DD'
    status       TEXT NOT NULL CHECK (status IN ('beklemede', 'onaylandı', 'reddedildi')),
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);

-- Yearly performance reviews (score 1-5)
CREATE TABLE performance_reviews (
    review_id     INTEGER PRIMARY KEY,
    employee_id   INTEGER NOT NULL,
    reviewer_id   INTEGER NOT NULL,              -- the employee who wrote the review
    review_year   INTEGER NOT NULL,
    score         INTEGER NOT NULL CHECK (score BETWEEN 1 AND 5),
    comment       TEXT,
    FOREIGN KEY (employee_id) REFERENCES employees(employee_id),
    FOREIGN KEY (reviewer_id) REFERENCES employees(employee_id)
);