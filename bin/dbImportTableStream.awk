BEGIN{ 
  writeOnce=0
  tableProcessing=0
  endProcess=0
}
{
  buffer = substr($0, 0, 150)
  line = $0
  if(match(buffer, /^DROP TABLE IF EXISTS `([^`]+)`;$/, arr) != 0) {
    tableName=arr[1]
    if (tableName == TABLE_NAME) {
      print "\033[44mbegin insert " tableName "\033[0m"  > "/dev/stderr"
      tableProcessing=1
    } else {
      if (! (tableName in map)) {
        print "ignore table " tableName  > "/dev/stderr"
      }
      map[tableName] = 1
    }
  } else if(match(buffer, /SET NAMES ([^ ]+)/, arr) != 0) {
    sub(/SET NAMES ([^ ]+)/, "SET NAMES " CHARACTER_SET, line)
    writeOnce=1
  }

  if (tableProcessing == 1) {
    if(match(buffer, /^commit;$/, arr) != 0) {  
      endProcess=1
    } else if(match(buffer, /SET character_set_client = ([^ ]+)/, arr) != 0 && substr(arr[1], 0, 1) != "@") {
      sub(/SET character_set_client = ([^ ]+)/, "SET character_set_client = " CHARACTER_SET, line)
    }
    print line
  }
  if (writeOnce == 1) {
    print line
    writeOnce=0
  }
  if (endProcess == 1) {
    exit 0
  }
}