---
name: teebi
description: Query, analyze, import, and visualize in-memory datasets using Steema TeeBI. Supports natural language querying, multidimensional summaries, and SVG charting.
---

# TeeBI Data Analytics Skill

Use this skill when you want to inspect, import, query, or visualize datasets with the TeeBI in-memory data engine.

## Available MCP Tools

- `teebi_list_datasets`: Lists all datasets available in the configured TeeBI store or directory.
- `teebi_get_schema`: Returns table name, row count, column names, column data types (Integer, Text, Float, DateTime), and sample values.
- `teebi_preview_data`: Returns the first $N$ rows as structured JSON.
- `teebi_query_sql`: Executes a TeeBI SQL query (e.g. `top 10 ProductName, sum(Amount) where Year>2020 group by ProductName`).
- `teebi_query_natural_language`: Runs a query against a dataset using natural language (e.g. "top 5 cuisines in Brooklyn with highest scores", "average movie length by year"). Translates the request to TeeBI SQL and returns both the query and data.
- `teebi_create_chart`: Generates an SVG vector graphic visualization (`bar`, `horiz_bar`, `line`, `pie`, `donut`, `area`).
- `teebi_summarize`: Multi-dimensional pivot aggregation using measures and dimensions (e.g. `count(name);cuisine`).
- `teebi_import_data`: Imports data from a local file (CSV, JSON, etc.) into the TeeBI store.
- `teebi_export_data`: Exports a dataset to CSV, JSON, or HTML.

## Typical Workflow

1. **Discovery**: Call `teebi_list_datasets` to see available tables.
2. **Schema**: Call `teebi_get_schema` for the dataset to know column names and types.
3. **Query**: Call `teebi_query_natural_language` with the user's question, or `teebi_query_sql` for exact TeeBI SQL.
4. **Visualize**: Call `teebi_create_chart` to render SVG charts directly for the user.
