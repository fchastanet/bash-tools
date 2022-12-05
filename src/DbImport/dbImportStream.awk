BEGIN{
  write=1
}
{
  buffer = substr($0, 1, 150)
  line = $0
  if(match(buffer, /^LOCK TABLES `([^`]+)` WRITE;$/, arr) != 0) {
    # check if inserts are part of the profile
    tableName=arr[1]
    if (! (tableName in map)) {
      profileCmd = "echo '" tableName "' | " PROFILE_COMMAND " | grep -q " tableName
      map[tableName] = (system(profileCmd) == 0)
    }
    if (map[tableName]) {
      print "\033[44mbegin insert " tableName "\033[0m"  > "/dev/stderr"
      line = line "\nTRUNCATE TABLE `" tableName "`;"
      write=1
    } else {
      print "ignore table " tableName  > "/dev/stderr"
      write=0
    }
  } else if(match(buffer, /^commit;$/, arr) != 0) {
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
  }


  if (write == 1) {
    print line
  }
}
