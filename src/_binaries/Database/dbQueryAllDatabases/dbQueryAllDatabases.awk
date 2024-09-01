BEGIN{
  headerPrinted=0
}
/^$/ {next}
{
  buffer = substr($0, 0, 35)
  line = $0
  if(buffer == "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@") {
    if (headerPrinted == 0) {
      line=substr(line, 36)
      headerPrinted=1
    } else {
      next
    }
  }
  print line

}
