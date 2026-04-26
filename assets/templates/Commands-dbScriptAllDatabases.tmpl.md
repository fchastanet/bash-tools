---
title: dbScriptAllDatabases
description: Execute a script on each database of specified MySQL server
weight: 10
type: docs
categories: [documentation]
tags: [commands, database]
creationDate: 2020-11-16
lastUpdated: 2026-02-15
version: '1.0'
---

## 1. Help

**Command:** `bin/dbScriptAllDatabases --help`

```text
@@@dbScriptAllDatabases_help@@@
```

## 2. Usage

Allow to execute a script on each database of specified mysql server

```bash
bin/dbScriptAllDatabases -d localhost-root dbCheckStructOneDatabase
```

or specified db only

```bash
bin/dbScriptAllDatabases -d localhost-root dbCheckStructOneDatabase db
```

launch script in parallel on multiple db at once

```bash
bin/dbScriptAllDatabases --jobs 10 -d localhost-root dbCheckStructOneDatabase
```
