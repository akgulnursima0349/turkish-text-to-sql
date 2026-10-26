# Turkish Text-to-SQL

A dataset and fine-tuned model for converting Turkish natural-language questions into SQL queries.

**Status:** Work in progress.

## Design decisions
- Database schemas use English table/column names, while questions and data are in Turkish. This mirrors real-world Turkish company databases and makes mapping Turkish questions to an English schema the core challenge.
- Every generated SQL query is validated by executing it against the database.

## Repository structure
- `schemas/` – database schemas (e-commerce, HR, accounting)
- `data/` – Turkish question–SQL pairs
- `eval/` – evaluation code and test set
- `notebooks/` – experiments and analysis
- `docs/` – design notes
