#!/bin/awk -f
# =========================================================================
#
# mysql2puml - SQL DDL to markdown converter
#
# Invocation/Execution:
#   awk -f mysql2puml.awk skinFile < inputFile > outputFile
#   DEBUG=1 awk -f mysql2puml.awk skinFile < inputFile > outputFile
#
# Supports
#   PlantUML format
# =========================================================================

function debug(first, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth, eleventh, twelfth) {
    if (DEBUG == 1) print("DEBUG - ", first, second, third, fourth, fifth, sixth, seventh, eighth, ninth, tenth, eleventh, twelfth) > "/dev/stderr"
}

# =========================================================================

function uml_start()
{
    if (!skinFile) {
        print("skinFile parameter missing") > "/dev/stderr"
        exit 1
    }
    while ((getline tmp < skinFile) > 0) {
        if (match(tmp, /@enduml/)) {
            break
        }
        print(tmp)
    }
    print "' entities"
}

# =========================================================================

function uml_end()
{
    print "@enduml"
}

# =========================================================================

function ltrim(s) { sub(/^[ \t\r\n]+/, "", s); return s }
function rtrim(s) { sub(/[ \t\r\n]+$/, "", s); return s }
function trim(s) { return rtrim(ltrim(s)); }

# =========================================================================

function column_weight(column)
{
    return (columnsDetails[column ",pk"] == "1" ? 8 : 0) \
        + (columnsDetails[column ",fk"] == "1" ? 4 : 0) \
        + (columnsDetails[column ",unique"] == "1" ? 2 : 0) \
        + (columnsDetails[column ",null"] == "0" ? 1 : 0)
}

function column_sort(i1, column1, i2, column2)
{
    weight1 = column_weight(column1)
    weight2 = column_weight(column2)
    if (weight1 == weight2) {
        l = tolower(column1)
        r = tolower(column2)

        if (l < r) {
            return -1
        } else if (l == r) {
            return 0
        } else {
            return 1
        }
    } else {
        return weight2 - weight1
    }
}

# =========================================================================

function uml_table(createTable)
# DDL to plantuml
# CREATE TABLE `core_customer` (`id` int(11) NOT NULL AUTO_INCREMENT, `instance_name` varchar(128) NOT NULL, PRIMARY KEY (`id`), UNIQUE KEY `instance_name` (`instance_name`) ) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8;
# CREATE TABLE `core_learner_skill` (`id` int(11) NOT NULL AUTO_INCREMENT, `customer_id` int(10) unsigned NOT NULL, PRIMARY KEY (`id`), KEY `customer_id_684f904f_fk_core_learner_id` (`customer_id`), CONSTRAINT `customer_id_684f904f_fk_core_customer_id` FOREIGN KEY (`customer_id`) REFERENCES `core_customer` (`id`)) ENGINE=InnoDB AUTO_INCREMENT=415 DEFAULT CHARSET=utf8;
#table( user ) {
#  primary_key( id ): UUID
#  column( isActive ): BOOLEAN
#}
#LearnerSkill "0..*" --> "1" Learner : "learner_id"
{
    debug("uml_table", createTable)
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
            columnType=arr[2]
            gsub(/\(|\)/, "", columnType)
            columnsDetails[columnName ",type"] = columnType  # eg: int(11) unsigned => int11 unsigned
            columnsDetails[columnName ",null"] = arr[7]=="NOT NULL" ? "0" : "1" # eg: NOT NULL
            columnsDetails[columnName ",autoIncrement"] = arr[8] # eg: AUTO_INCREMENT
        }
    }

    if (DEBUG == 1) {
        debug("Table ", tableName)
        for (i in columns) debug("column ", i, " ", columns[i])
        for (i in columnsDetails) debug("match ", i, " ", columnsDetails[i])
    }
    asort(columns, columns, "column_sort")
    if (DEBUG == 1) {
        debug("***************************************************************")
        debug("Columns order after sort")
        for (i in columns) debug("column ", i, " ", columns[i], column_weight(columns[i]))
    }
    printf("Table(%s) { \n", tableName )
    for(i in columns) {
        columnName=columns[i]
        # column($name, $type, $null="", $pk="", $fk="", $unique="")
        printf( \
            "  column(\"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\")\n", \
            columnName, \
            trim(columnsDetails[columnName ",type"]), \
            (columnsDetails[columnName ",null"] == "1") ? "NULL" : "NOT NULL", \
            (columnsDetails[columnName ",pk"] == "1") ? "PK" : "", \
            (columnsDetails[columnName ",fkTable"] == "1") ? "FK" : "", \
            (columnsDetails[columnName ",unique"] == "1") ? "UNIQUE" : "" \
        )
    }
    print("}")

    for(i in columns) {
        columnName=columns[i]
        if (columnsDetails[columnName ",fk"] == "1") {
            #LearnerSkill "0..*" --> "1" Learner : "learner_id"
            printf("%s \"0..*\" --> \"1\" %s : \"%s\"\n", tableName, columnsDetails[columnName ",fkTable"], columnsDetails[columnName ",fkColumn"] )
        }
    }
    print("")

    delete columnsDetails
    delete columns
}

# =========================================================================
function uml_parse_line(currentLine)
{
    if (length(currentLine) < 2 || match(currentLine, "^--") > 0) {
        return
    }

    if (match(currentLine,";")>0) {
        sqlLine = sqlLine "\n" currentLine
        debug(sqlLine)
        if (match(sqlLine,"CREATE TABLE") > 0) {
            uml_table(sqlLine)
        }
        sqlLine=""
    }
    else {
        sqlLine = sqlLine "\n" currentLine
    }
}

# =========================================================================

BEGIN {
    DEBUG=ENVIRON["DEBUG"]
    skinFile=ARGV[1]
    debug("Skin file", skinFile)
    uml_start()
}

{
    line=$0
    uml_parse_line(line)
}

END {
    uml_end()
    exit 0
    # fake call occuring after exit to remove warning about unused function
    column_sort()
}
# =========================================================================
