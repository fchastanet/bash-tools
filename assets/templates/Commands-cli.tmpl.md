---
title: cli
description: Easy connection to docker container.
weight: 10
type: docs
categories: [documentation]
tags: [commands, development tools]
creationDate: 2020-11-16
lastUpdated: 2026-02-15
version: '1.0'
---

## 1. Help

**Command:** `bin/cli --help`

```text
@@@cli_help@@@
```

## 2. Example 1: open bash on a container named web

```bash
cli web
```

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=
apache2 //bin/bash
```

## 3. Example 2: connect to mysql container with root user

```bash
cli mysql root bash
```

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" -it --user=root
project-mysql bash
```

## 4. Example 3: connect to mysql server in order to execute a query

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -it -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=mysql
project-mysql //bin/bash -c 'mysql -h127.0.0.1 -uroot -proot -P3306'
```

## 5. Example 4: pipe sql command to mysql container

```bash
echo 'SELECT
  table_schema AS "Database",
  ROUND(SUM(data_length + index_length) / 1024 / 1024, 2) AS "Size (MB)"
FROM information_schema.TABLES' | bin/cli mysql
```

will actually execute this command :

```bash
MSYS_NO_PATHCONV=1 MSYS2_ARG_CONV_EXCL='\*'
docker exec -i -e COLUMNS="$(tput cols)" -e LINES="$(tput lines)" --user=mysql
project-mysql //bin/bash -c 'mysql -h127.0.0.1 -uroot -proot -P3306'
```

notice that as input is given to the command, tty option is not provided to docker exec
