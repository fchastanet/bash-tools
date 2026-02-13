BEGIN{
  write=1
  inCreateTable=0
  createTableName=""
}
{
  buffer = substr($0, 1, 150)
  line = $0

  # Fix malformed MySQL version comments - add space before */
  if (match(line, /\/\*![0-9]+[^*]*\*\//, arr)) {
    # Check if there's no space before */
    if (match(line, /\/\*![0-9]+[^*]*[^ ]\*\//, arr)) {
      gsub(/(\*\/)/, " */", line)
    }
  }

  if(match(buffer, /^INSERT INTO `([^`]+)`/, arr) != 0) {
    # check if inserts are part of the profile
    tableName=arr[1]
    if (! (tableName in map)) {
      profileCmd = "echo '" tableName "' | " PROFILE_COMMAND " | grep -q " tableName
      map[tableName] = (system(profileCmd) == 0)
    }
    if (map[tableName]) {
      print "\033[44m" "begin insert " tableName "\033[0m"  > "/dev/stderr"
      write=1
    } else {
      print "ignore table " tableName  > "/dev/stderr"
      write=0
    }
  } else if(match(buffer, /^;$/, arr) != 0) {
    write=1
  } else if(match(buffer, /SET NAMES ([^ ]+)/, arr) != 0) {
    if (CHARACTER_SET != "") {
      sub(/SET NAMES ([^ ]+)/, "SET NAMES " CHARACTER_SET, line)
    }
    write=1
  } else if(match(buffer, /SET character_set_client = ([^ ]+)/, arr) != 0 && substr(arr[1], 0, 1) != "@") {
    if (CHARACTER_SET != "") {
      sub(/SET character_set_client = ([^ ]+)/, "SET character_set_client = " CHARACTER_SET, line)
    }
    write=1
  } else if(match(buffer, /^CREATE TABLE `([^`]+)`/, arr) != 0) {
    # Convert CREATE TABLE to CREATE TABLE IF NOT EXISTS
    tableName = arr[1]
    if (!match(line, /IF NOT EXISTS/)) {
      sub(/CREATE TABLE `([^`]+)`/, "CREATE TABLE IF NOT EXISTS `" tableName "`", line)
    }
    inCreateTable = 1
    createTableName = tableName
    write=1
  } else if(inCreateTable && match(line, /;[ \t]*$/, arr) != 0) {
    # End of CREATE TABLE statement - add TRUNCATE after the semicolon
    line = line "\nTRUNCATE TABLE `" createTableName "`;"
    inCreateTable = 0
    createTableName = ""
    write=1
  }

  if (write == 1) {
    print line
  }
}
