---
title: dbQueryAllDatabases
description: Execute a query on multiple databases to generate a report.
weight: 10
type: docs
categories: [documentation]
tags: [commands, database]
creationDate: 2020-11-16
lastUpdated: 2026-02-15
version: '1.0'
---

## 1. Help

**Command:** `bin/dbQueryAllDatabases --help`

```text
@@@dbQueryAllDatabases_help@@@
```

## 2. Usage

Execute a query on multiple database in order to generate a report, query can be parallelized on multiple databases

```bash
bin/dbQueryAllDatabases -e localhost-root conf/dbQueries/databaseSize.sql
```
