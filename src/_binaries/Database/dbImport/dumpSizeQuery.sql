SELECT ROUND(SUM(data_length + index_length) / 1024 / 1024, 0) AS size
FROM information_schema.TABLES WHERE table_schema='${fromDbName}'
AND table_name IN(${listTablesDumpSize}, 'dummy')
GROUP BY table_schema
