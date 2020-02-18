# bash-framework/Array.sh
# Functions
# function `Array::contains`
> ***Public***

check if an element is contained in an array

**Arguments**:

* $@ - first parameter is the needle, rest is the array

**Examples**:

```shell
  Array::contains "$libPath" "${__bash_framework__importedFiles[@]}"
```

Returns 0 if found, 1 otherwise
