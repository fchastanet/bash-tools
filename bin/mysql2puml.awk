# =========================================================================
#
# mysql2puml - SQL DDL to markdown converter
#
# Invocation/Execution:
#   mysql2puml inputfile > outputfile
#   DEBUG=1 mysql2puml inputfile > outputfile
#
# Supports
#   PlantUML format
# =========================================================================
# Globals
running=0
help=0
exitCode=0
DEBUG=0

# =========================================================================
function debug(first, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth, eleventh, twelfth) {
    if (DEBUG == 1) print("DEBUG - ", first, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth, eleventh, twelfth) > "/dev/stderr"
}

# =========================================================================
function check_arguments() {

    debug(ARGC)
    if (ARGC==1 || ARGC>3) {
        print_usage()
        exit
    }

    for (i=1; i<= ARGC; i++) {
        debug(ARGV[i])
        if (ARGV[i] == "--help" ) print_help()
        if (ARGV[i] == "--version" ) print_version()
    }

    # check if arg 2 is a file and exist
    # check if arg 3 is a file and exist
    running=1
}

function print_usage() {
    help=1
    exitCode = 1
    print("Usage: mysql2puml --help ")
    print("Usage: mysql2puml --version")
    print("Usage: mysql2puml inputSqlFile [confFile]")
    exit
}

function print_version() {
    help=1
    print("mysql2puml Version: 0.1")
    exit
}

function print_help() {
    help=1
    print("mysql2puml Help")
    print_usage()
    print("options:")
    print("  --version      : display version and exit")
    print("  --help         : display this help and exit")
    print("  inputSqlFile : sql filepath to parse")
    print("  confFile     : (optional) header configuration of the plant uml file")
    print("")
    print("Examples")
    print("mysql2puml dump.dql")
    print("")
    print("mysqldump --skip-add-drop-table --skip-add-locks --skip-disable-keys --skip-set-charset --user=root --password=root --no-data skills | mysql2puml")
    exit
}

function uml_start()
{
    while ((getline tmp < skinFile) > 0) {
        if (match(tmp, /@enduml/)) {
            break
        }
        print(tmp)
    }
    print "' entities"
    running=1
}

function uml_end()
{
    print "@enduml"
}

function erase_braces(mystr)
{
    #sub("\(","",mystr)
    split(mystr,arr,"(")
    return arr[1]
}

function uml_table(createTable)
# DDL to plantuml
# CREATE TABLE `core_customer` (`id` int(11) NOT NULL AUTO_INCREMENT, `instance_name` varchar(128) NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY `instance_name` (`instance_name`) ) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
# CREATE TABLE `core_learnerskill` (`id` int(11) NOT NULL AUTO_INCREMENT, `customer_id` int(10) unsigned NOT NULL, PRIMARY KEY (`id`), KEY `customer_id_684f904f_fk_core_learner_id` (`customer_id`), CONSTRAINT `customer_id_684f904f_fk_core_customer_id` FOREIGN KEY (`customer_id`) REFERENCES `core_customer` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=415 DEFAULT CHARSET=utf8;
#table( user ) {
#  primary_key( id ): UUID
#  column( isActive ): BOOLEAN
#}
#LearnerSkill "0..*" --> "1" Learner : "learner_id"
{
    split(createTable,lines,"\n")
    columnIdx=0
    for (line in lines) {
        debug(lines[line])
        if (match(lines[line], /CREATE TABLE `([^`]+)` \(/, arr)) {
            debug("TABLE ", lines[line])    
            tableName = arr[1]
        } else if (match(lines[line], /PRIMARY KEY \(([^)]+)\)/, arr)) {
            # PRIMARY KEY (`id`),
            debug("PK ", lines[line])    
            split(arr[1],primaryKeys,",")
            for (i in primaryKeys) {
                if(match(primaryKeys[i], /[ ]?`([^`]+)+`[ ]?/, arr)) {
                    columnsDetails[arr[1] ",pk"] = "1"
                }
            }
        } else if (match(lines[line], /CONSTRAINT `[^`]+` FOREIGN KEY \(`([^`]+)`\) REFERENCES `([^`]+)` \(`([^`]+)`\)/, arr)) {
            # CONSTRAINT `core_learner_customer_id_6d356da8_fk_core_customer_id` FOREIGN KEY (`customer_id`) REFERENCES `core_customer` (`id`)
            debug("Constraint ", lines[line])
            columnName=arr[1]
            columnsDetails[columnName ",fk"]="1"
            columnsDetails[columnName ",fkTable"]=arr[2]
            columnsDetails[columnName ",fkColumn"]=arr[3]
        } else if (match(lines[line], /UNIQUE KEY `[^`]+` \(([^)]+)\)/, arr)) {
            # UNIQUE KEY `unique_learner_by_customer` (`external_id`,`customer_id`),
            debug("Unique Key ", lines[line])    
            split(arr[1],uniqueKeys,",")
            for (i in uniqueKeys) {
                if(match(uniqueKeys[i], /[ ]?`([^`]+)+`[ ]?/, arr)) {
                    columnsDetails[arr[1] ",unique"] = "1"
                }
            }
        } else if (match(lines[line], /`([^`]+)` (([A-Za-z]+)((\([^)]+\)|)[ ]?(unsigned|)))[ ]?(NOT NULL|NULL|)[ ]?(AUTO_INCREMENT|)/, arr)) {
            # `id` int(11) NOT NULL AUTO_INCREMENT
            # `test` int(11) unsigned NULL
            # `instance_name` varchar(128) NOT NULL
            debug("Column ", lines[line])    
            columnName = arr[1]
            columns[columnIdx++] = columnName
            columnsDetails[columnName ",type"] = arr[2] # eg: int(11) unsigned
            columnsDetails[columnName ",null"] = arr[7]=="NOT NULL" ? "0" : "1" # eg: NOT NULL
            columnsDetails[columnName ",autoIncrement"] = arr[8] # eg: AUTO_INCREMENT
        }
    }

    if (DEBUG == 1) {
        print("Table ", tableName)
        for (i in columns) print("column ", i, " ", columns[i])
        for (i in columnsDetails) print("match ", i, " ", columnsDetails[i])
    }
    printf("Table(%s, \"%s\") { \n", tableName, tableName )
    for(i in columns) {
        columnName=columns[i]
        if (columnsDetails[columnName ",pk"] == "1") {
            printf("primary_key( %s ) %s\n", columnName, columnsDetails[columnName ",type"])
        } else if (columnsDetails[columnName ",unique"] == "1") {
            printf("unique( %s ) %s\n", columnName, columnsDetails[columnName ",type"])
        } else {
            printf("%s %s\n", columnName, columnsDetails[columnName ",type"])
        }
    }
    print("}")

    for(i in columns) {
        columnName=columns[i]
        if (columnsDetails[columnName ",fk"] == "1") {
            #LearnerSkill "0..*" --> "1" Learner : "learner_id"
            printf("%s \"0..*\" --> \"1\" %s : \"%s\"\n", tableName, columnsDetails[columnName ",fkTable"], columnsDetails[columnName ",fkColumn"] )
        }
    }

    delete columnsDetails
    delete columns
}

# =========================================================================

function convert_type(type)
{
    return type
}

# =========================================================================

function uml_parse_sql_line(sqlLine)
{
    debug("uml_parse_sql_line",sqlLine)
    if (match(sqlLine,"CREATE TABLE") > 0) {
        uml_table(sqlLine)
    }
}
# =========================================================================
function uml_parse_line(line)
{
    if (length(line) < 2 || match(line, "^--") > 0) {
        return
    }
 
    if (match(line,";")>0) {
        sql_line = sql_line "\n" line
        uml_parse_sql_line(sql_line)
        sql_line=""
    }
    else {
        sql_line = sql_line "\n" line
    }
}

# =========================================================================

BEGIN {
    DEBUG=ENVIRON["DEBUG"]
    skinFile=ENVIRON["PWD"] "/mysql2puml.default-skin.puml"
    check_arguments()
    uml_start()
}

{
    line=$0
    uml_parse_line(line)
}

END {    
    if (help == 0) {
        uml_end() 
    }
    exit exitCode
}

# =========================================================================
