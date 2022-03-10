SELECT
  database,
  table,
  column,
  type,
  sum(rows) AS rows,
  sum(column_data_compressed_bytes) AS compressed_bytes,
  formatReadableSize(compressed_bytes) AS compressed,
  formatReadableSize(sum(column_data_uncompressed_bytes)) AS uncompressed,
  sum(column_data_uncompressed_bytes) / compressed_bytes AS ratio,
  any(compression_codec) AS codec
FROM system.parts_columns AS pc
LEFT JOIN system.columns AS c
ON (pc.database = c.database) AND (c.table = pc.table) AND (c.name = pc.column)
WHERE (database LIKE '%') AND (table LIKE '%') AND active
GROUP BY
  database,
  table,
  column,
  type
ORDER BY database, table, sum(column_data_compressed_bytes) DESC
