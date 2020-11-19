# TODO import script directly to mysql server
# TODO pass mysql parameters to awk script
BEGIN{ 
  write=1
}
{
  buffer = substr($0, 0, 150)
  print "buffer " buffer  > "/dev/stderr"
  if(match(buffer, /^LOCK TABLES `([^`]+)` WRITE;$/, arr) != 0) {
    # check if inserts are part of the profile
    profileCmd = "echo '" arr[1] "' | " PROFILE " | grep -q " arr[1]
    if (system(profileCmd) == 0) {
      print "begin insert " arr[1]  > "/dev/stderr"
      write=1
    } else {
      print "ignore table " arr[1]  > "/dev/stderr"
      write=0
    }
    close(profileCmd)
  } else if(buffer, /^commit;$/, arr) != 0) {
    write=1
  } else if(buffer, /^commit;$/, arr) != 0) {
    
  }

  if (write == 1) {
    print
  }
}