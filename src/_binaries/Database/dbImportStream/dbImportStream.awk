BEGIN{
  write=1
}

function ShouldIncludeTable(tableName) {
  if (! (tableName in map)) {
    profileCmd = "echo '" tableName "' | " PROFILE_COMMAND " | grep -q " tableName
    map[tableName] = (system(profileCmd) == 0)
    if (map[tableName]) {
      print "\033[44m" "begin insert " tableName "\033[0m"  > "/dev/stderr"
    } else {
      print "exclude table " tableName  > "/dev/stderr"
    }
  }
  return map[tableName]
}

{
  buffer = substr($0, 1, 150)
  line = $0
  if(match(buffer, /^LOCK TABLES `([^`]+)` WRITE;$/, arr) != 0) {
    # check if inserts are part of the profile
    tableName=arr[1]
    if (ShouldIncludeTable(tableName)) {
      if (RESET==1) {
        print "\033[44m" "reset mode - truncate table " tableName "\033[0m"  > "/dev/stderr"
        line = "\nTRUNCATE TABLE `" tableName "` IF EXISTS;\n" line
      }
      write=1
    } else {
      write=0
    }
  } else if(match(buffer, /^CREATE TABLE `([^`]+)` \($/, arr) != 0) {
    tableName=arr[1]
    if (ShouldIncludeTable(tableName) && RESET==1) {
      print "\033[44m" "reset mode - drop table " tableName "\033[0m"  > "/dev/stderr"
      line = "\nDROP TABLE IF EXISTS `" tableName "`;\nCREATE TABLE `" tableName "` (\n"
    } else {
      line = "CREATE TABLE IF NOT EXISTS `" tableName "` (\n"
    }
    write=1
  } else if(match(buffer, /^INSERT INTO `([^`]+)` VALUES/, arr) != 0) {
    # check if inserts are part of the profile
    tableName=arr[1]
    write=ShouldIncludeTable(tableName)
  } else if(match(buffer, /^commit;$/, arr) != 0) {
    write=1
  } else if(match(buffer, /SET NAMES ([A-Za-z0-9_-]+)/, arr) != 0) {
    if (CHARACTER_SET != "") {
      sub(/SET NAMES ([A-Za-z0-9_-]+)/, "SET NAMES " CHARACTER_SET, line)
    }
    write=1
  } else if(match(buffer, /SET character_set_client = ([A-Za-z0-9_-]+)/, arr) != 0 && substr(arr[1], 0, 1) != "@") {
    if (CHARACTER_SET != "") {
      sub(/SET character_set_client = ([A-Za-z0-9_-]+)/, "SET character_set_client = " CHARACTER_SET, line)
    }
    write=1
  }

  if (write == 1) {
    print line
  }
}
