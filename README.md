# bash-tools

## The tools
### bin/dbQueryAllDatabases

Run the example
```bash
bin/dbQueryAllDatabases -e dbQueriesSample/localhost-root.env dbQueriesSample/databaseSize.sql
```

Help
```
Usage: dbQueryAllDatabases [-h|--help]
Usage: dbQueryAllDatabases <query|queryFile> [--env-file|-e <envfile>] [-t|--as-tsv] [-q|--query] [--jobs|-j <numberOfJobs>] [--bar|-b]
    --help,-h prints this help and exits
    --as-tsv,-t show results as tsv file (separated by tabulations)
    --query,-q implies <query> parameter is a mysql query string
    --jobs,-j <numberOfJobs> specify the number of db to query in parallel (this needs the use of gnu parallel)
    --bar,-b Show progress as a progress bar. In the bar is shown: % of jobs completed, estimated seconds left, and number of jobs started.
    <query|queryFile>
        if -q option is provided this parameter is a mysql query string
        else a file must be specified
    --env-file,-e <envfile> load <envfile>, this file must contains these variables in order to connect to the mysql server
MYSQL_HOSTNAME=""
MYSQL_USER=""
MYSQL_PASSWORD=""
MYSQL_PORT=""
REMOTE_MYSQL_HOSTNAME=""
REMOTE_MYSQL_PORT=""
REMOTE_MYSQL_USER=""
REMOTE_MYSQL_PASSWORD=""

    local DB connection  : root:root@127.0.0.1:3306
    remote DB connection : root:root@remoteDB:3306
```

### bin/dbImport
Import remote db into local db
```bash
bin/dbImport ExampleDbName
```

Help
```
Command: dbImport --help prints this help and exits
Command: dbImport <remoteDbName> [<localDbName>] [-f|--force] [-d|--download-dump] [-s|--skip-schema]
                        [-p|--profile profileName] [-o|--collation-name utf8_general_ci] [-c|--character-set utf8]

    <localDbName> : use remote db name if not provided
    -f|--force If local db exists, it will overwrite it
    -d|--download-dump force remote db dump (default: use already downloaded dump in /home/vagrant/projects/bash-tools/mysqlDumps if available)
    -s|--skip-schema avoid to import the schema
    -o|--collation-name change the collation name used during database creation (default value: collation name used by remote db)
    -c|--character-set change the character set used during database creation (default value: character set used by remote db)
    -p|--profile profileName the name of the profile to use in order to include or exclude tables
        (if not specified /home/vagrant/.dbImportProfiles/default.sh  is used if exists otherwise /home/vagrant/projects/bash-tools/dbImportProfiles/default.sh)
        list of available home profiles (/home/vagrant/.dbImportProfiles): none, bugProd, default, smartgroup, sample, precomputeLearnerTimezone, all
        list of available profiles : none, default, all

    local DB connection  : root:root@127.0.0.1:3306
    remote DB connection  : root:root@remoteDB:3306
```

### bin/dbImportTable
Import remote db table into local db
```bash
bin/dbImport ExampleDbName ExampleTableName
```

Help
```
Command: dbImportTable [--help] prints this help and exits
Command: dbImportTable <remoteDbName> <tableName> [<localDbName>] [-d|--download-dump] [-f|--force] [-o|--collation-name utf8_general_ci] [-c|--character-set utf8]

    download the remote table data and install data in local database (the schema should exists)

    <tableName>   : table name to import
    <localDbName> : use remote db name if not provided
    -f|--force If local db exists, it will overwrite it
    -d|--download-dump force remote db dump (default: use already downloaded dump in /home/vagrant/projects/bash-tools/mysqlDumps if available)
    -o|--collation-name change the collation name used during database creation (default value: collation name used by remote db)
    -c|--character-set change the character set used during database creation (default value: character set used by remote db)

    local DB connection  : root:root@127.0.0.1:3306
    remote DB connection : root:root@remoteDB:3306
```
## Framework

## Unit tests

## Install
install GNU parallel

## Acknowledgements
Like so many projects, this effort has roots in many places. 

I would like to thank particularly  Bazyli Brzóska for his work on the project [Bash Infinity](https://github.com/niieani/bash-oo-framework).
Framework part of this project is largely inspired by his work(some parts copied). You can see his [blog](https://invent.life/project/bash-infinity-framework) too that is really interesting 

TODO bats
