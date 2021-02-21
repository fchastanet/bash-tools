# Rename table
# variables
# SOURCE_TABLE
# TARGET_TABLE
BEGIN{ 
  RENAME=(SOURCE_TABLE != TARGET_TABLE)
  pattern="^(LOCK TABLES|DROP TABLE IF EXISTS|CREATE TABLE|\\/\\*![[:digit:]]+ ALTER TABLE|INSERT INTO) `(" SOURCE_TABLE ")`"
}
{
  line = $0
  buffer = substr($0, 0, 150)
}
buffer ~ pattern {
  if (RENAME) {
    line = gensub(/^(LOCK TABLES|DROP TABLE IF EXISTS|CREATE TABLE|\/\*![0-9]+ ALTER TABLE|INSERT INTO) `([^`]+)`/, "\\1 `" TARGET_TABLE "`", "g", line)
  }
}
{
  print line
}
