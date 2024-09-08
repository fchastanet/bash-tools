#!/usr/bin/env bash

optionRatioHelpFunction() {
  echo "    define the ratio to use (0 to 100% - default 70)."
  echo "      - 0 means profile will filter out all the tables."
  echo "      - 100 means profile will keep all the tables."
  echo "    Eg: 70 means that tables with size(table+index)"
  echo "    that are greater than 70% of the max table size"
  echo "    will be excluded."
}
