---
title: dbImportProfile
description: Generate profile for dbImport to filter out tables based on size ratio.
weight: 10
type: docs
categories: [documentation]
tags: [commands, database]
creationDate: 2020-11-16
lastUpdated: 2026-02-15
version: '1.0'
---

## 1. Help

**Command:** `bin/dbImportProfile --help`

```text
@@@dbImportProfile_help@@@
```

## 2. Usage

Import remote db into local db

```bash
dbImportProfile --from-dsn default.local MY_DB --ratio 45
```

Ability to generate profile that can be used in dbImport to filter out tables bigger than given ratio (based on biggest
table size). Profile is automatically saved in ${HOME}/.bash-tools/dbImportProfiles with this format `auto*<dsn>*<db>`
**eg:** auto_default.local_MY_DB
