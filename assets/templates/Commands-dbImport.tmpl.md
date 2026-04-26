---
title: dbImport
description: Import source db into target db using eventual table filter.
weight: 10
type: docs
categories: [documentation]
tags: [commands, database]
creationDate: 2020-11-16
lastUpdated: 2026-02-15
version: '1.0'
---

## 1. Help

**Command:** `bin/dbImport --help`

```text
@@@dbImport_help@@@
```

## 2. Usage

Import default source dsn/db ExampleDbName into default target dsn/db ExampleDbName

```bash
dbImport ExampleDbName
```

Ability to import db from dump stored on aws the dump file should have this name `<fromDbName>.tar.gz` and stored on AWS
location defined by S3_BASE_URL env variable (see `src/_binaries/Database/dbImport/testsData/.env` file)

```bash
dbImport --from-aws ExampleDbName.tar.gz
```

It allows also to dump from source database and import it into target database. Providing --profile option **dumps**
only the tables selected. Providing --tables option **imports** only the tables selected.

The following command will dump full structure and data of fromDb but will insert only the data from tableA and tableB,
full structure will be inserted too. Second call to this command skip the dump as dump has been saved the first time.
Note that table A and table B are truncated on target database before being imported.

```bash
dbImport --from-dsn default.remote --target-dsn default.local -p all \
  fromDb targetDB --tables tableA,tableB
```
