# TODO import script directly to mysql server
# TODO pass mysql parameters to awk script
BEGIN{ 
  write=0
  endProcess=0
}
{
  buffer = substr($0, 0, 150)
  line = $0
  if(match(buffer, /^INSERT INTO `([^`]+)`/, arr) != 0) {
    # check if inserts are part of the profile
    tableName=arr[1]
    if (tableName == TABLE_NAME) {
      print "begin insert " tableName  > "/dev/stderr"
      write=1
    } else {
      print "ignore table " tableName  > "/dev/stderr"
      write=0
    }
  } else if(match(buffer, /^commit;$/, arr) != 0) {
    if (write == 1) {
      endProcess=1
      write=0
    }
  }

  if (write == 1) {
    print line
  }
  if (endProcess == 1) {
    exit 0
  }
}