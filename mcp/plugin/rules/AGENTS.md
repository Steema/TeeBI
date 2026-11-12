# TeeBI Analytics Agent Rules

When answering questions about TeeBI datasets, querying data, or producing charts:

1. **Always inspect schema first**: Call `teebi_get_schema` or `teebi_list_datasets` before writing raw SQL so you know exact column names and data types.
2. **Prefer Natural Language Queries**: Use `teebi_query_natural_language` for flexible human questions. It automatically parses user intents into TeeBI SQL and returns both the query and the data rows.
3. **TeeBI SQL Dialect**:
   - Aggregate expressions: `sum(Col)`, `average(Col)`, `count(Col)`, `min(Col)`, `max(Col)`.
   - Grouping: `group by Col1, Col2`.
   - Limiting: `top N ...` (e.g. `top 10 ProductName, sum(Amount) group by ProductName`).
   - Semicolon summary format: `measure1, measure2; dimension1, dimension2`.
4. **Visualizations**: Use `teebi_create_chart` to render SVG charts for any query or dataset. SVG can be embedded directly or saved to file.
