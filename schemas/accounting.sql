-- Accounting schema for Turkish Text-to-SQL
-- Dialect: SQLite
-- Account codes follow the Turkish Uniform Chart of Accounts (Tek Düzen Hesap Planı)

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS journal_lines;
DROP TABLE IF EXISTS journal_entries;
DROP TABLE IF EXISTS cash_transactions;
DROP TABLE IF EXISTS invoice_lines;
DROP TABLE IF EXISTS invoices;
DROP TABLE IF EXISTS parties;
DROP TABLE IF EXISTS accounts;

-- Chart of accounts (e.g. '100' Kasa, '102' Bankalar, '120' Alıcılar, '320' Satıcılar, '600' Yurt İçi Satışlar)
CREATE TABLE accounts (
    account_code  TEXT PRIMARY KEY,
    name          TEXT NOT NULL,
    account_type  TEXT NOT NULL CHECK (account_type IN ('varlık', 'kaynak', 'gelir', 'gider'))
);

-- Business partners: customers and suppliers (cari hesaplar)
CREATE TABLE parties (
    party_id    INTEGER PRIMARY KEY,
    name        TEXT NOT NULL,
    party_type  TEXT NOT NULL CHECK (party_type IN ('müşteri', 'tedarikçi')),
    tax_number  TEXT UNIQUE,                 -- vergi numarası
    city        TEXT NOT NULL
);

-- Sales and purchase invoices
CREATE TABLE invoices (
    invoice_id    INTEGER PRIMARY KEY,
    invoice_no    TEXT NOT NULL UNIQUE,       -- e.g. 'FTR2026000123'
    party_id      INTEGER NOT NULL,
    invoice_type  TEXT NOT NULL CHECK (invoice_type IN ('satış', 'alış')),
    issue_date    TEXT NOT NULL,              -- 'YYYY-MM-DD'
    due_date      TEXT NOT NULL,              -- 'YYYY-MM-DD'
    status        TEXT NOT NULL CHECK (status IN ('ödenmedi', 'kısmen ödendi', 'ödendi', 'iptal')),
    FOREIGN KEY (party_id) REFERENCES parties(party_id)
);

-- Line items of each invoice; VAT (KDV) is stored per line
CREATE TABLE invoice_lines (
    line_id      INTEGER PRIMARY KEY,
    invoice_id   INTEGER NOT NULL,
    description  TEXT NOT NULL,
    quantity     REAL NOT NULL CHECK (quantity > 0),
    unit_price   REAL NOT NULL CHECK (unit_price >= 0),   -- excluding VAT, in TL
    vat_rate     INTEGER NOT NULL CHECK (vat_rate IN (0, 1, 10, 20)),   -- KDV oranı (%)
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);

-- Money received from customers (tahsilat) or paid to suppliers (ödeme)
CREATE TABLE cash_transactions (
    transaction_id    INTEGER PRIMARY KEY,
    invoice_id        INTEGER,                 -- NULL if not linked to an invoice
    party_id          INTEGER NOT NULL,
    transaction_type  TEXT NOT NULL CHECK (transaction_type IN ('tahsilat', 'ödeme')),
    method            TEXT NOT NULL CHECK (method IN ('nakit', 'banka havalesi', 'kredi kartı', 'çek')),
    amount            REAL NOT NULL CHECK (amount > 0),
    transaction_date  TEXT NOT NULL,           -- 'YYYY-MM-DD'
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id),
    FOREIGN KEY (party_id) REFERENCES parties(party_id)
);

-- Journal entries (yevmiye kayıtları)
CREATE TABLE journal_entries (
    entry_id     INTEGER PRIMARY KEY,
    entry_date   TEXT NOT NULL,               -- 'YYYY-MM-DD'
    description  TEXT NOT NULL,
    invoice_id   INTEGER,                     -- optional link to an invoice
    FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id)
);

-- Lines of each journal entry; each line is either a debit (borç) or a credit (alacak)
-- For every entry, total debit must equal total credit
CREATE TABLE journal_lines (
    journal_line_id  INTEGER PRIMARY KEY,
    entry_id         INTEGER NOT NULL,
    account_code     TEXT NOT NULL,
    debit            REAL NOT NULL DEFAULT 0 CHECK (debit >= 0),    -- borç
    credit           REAL NOT NULL DEFAULT 0 CHECK (credit >= 0),   -- alacak
    CHECK ((debit > 0 AND credit = 0) OR (credit > 0 AND debit = 0)),
    FOREIGN KEY (entry_id) REFERENCES journal_entries(entry_id),
    FOREIGN KEY (account_code) REFERENCES accounts(account_code)
);