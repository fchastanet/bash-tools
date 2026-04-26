---
title: mysql2puml
description: Convert MySQL database schema to PlantUML format.
weight: 10
type: docs
categories: [documentation]
tags: [commands, converters]
creationDate: 2020-11-16
lastUpdated: 2026-02-15
version: '1.0'
---

## 1. Help

**Command:** `bin/mysql2puml --help`

```text
@@@mysql2puml_help@@@
```

## 2. Example

Mysql dump of some tables

```bash
mysqldump --skip-add-drop-table --skip-add-locks \
  --skip-disable-keys --skip-set-charset \
  --host=127.0.0.1 --port=3345 --user=root --password=root \
  --no-data skills \
  $(mysql --host=127.0.0.1 --port=3345 --user=root --password=root skills \
    -Bse "show tables like 'core\_%'") |
  grep -v '^\/\*![0-9]\{5\}.*\/;$' >doc/schema.sql
```

Transform mysql dump to plant uml format

```bash
mysql2puml \
  src/_binaries/Converters/testsData/mysql2puml.dump.sql \
  -s default >src/_binaries/Converters/testsData/mysql2puml.dump.puml
```

Plantuml diagram generated

```plantuml
@@@mysql2puml_plantuml_diagram@@@
```

using plantuml software, here an example of resulting diagram

{{< img src="assets/mysql2puml-model.png" alt="resulting database diagram" >}}
