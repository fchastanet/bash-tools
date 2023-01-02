SET @db = (SELECT DATABASE());

SELECT @db AS "Database",
  COALESCE(ROUND(SUM(data_length + index_length) / 1024 / 1024, 2), 0) AS "Size (MB)",
  COUNT(*) as "Tables Count"
FROM information_schema.TABLES
WHERE table_schema=@db;
