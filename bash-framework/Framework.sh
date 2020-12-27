#!/usr/bin/env bash

declare -ag __bash_framework__importedFiles

# Public: exits with message if current user is not the expected one
#
# **Arguments**:
# * $1 expected user login
#
# **Exit**: code 1 if current user is not the expected one
Framework::expectUser() {
    local expectedUserName="$1"
    local currentUserName

    currentUserName=$(id -u -n)
    [  "${currentUserName}" != "${expectedUserName}" ] &&
        Log::fatal "The script must be run as ${expectedUserName}"
}

# Public: exits with message if current user is root
#
# **Exit**: code 1 if current user is root
Framework::expectNonRootUser() {
    local currentUserName

    currentUserId=$(id -u)
    if [  "${currentUserId}" = "0" ]; then
      Log::fatal "The script must not be run as root"
    fi
}

# Public: exits with message if expected global variable is not set
#
# **Arguments**:
# * $1 expected global variable
#
# **Exit**: code 1 if expected global variable is not set
Framework::expectGlobalVariables() {
    for var in "${@}"
    do
        [[ -v "${var}" ]] || Log::fatal "Variable ${var} is unset"
    done
}

# Public: get absolute file from relative path
#
# **Arguments**:
# * $1 relative file path
#
# **Output**: absolute path (can be $1 if $1 begins with /)
Framework::GetAbsolutePath() {
  # http://stackoverflow.com/questions/3915040/bash-fish-command-to-print-absolute-path-to-a-file
  # $1 : relative filename
  local file="$1"
  if [[ "$file" == "/"* ]]
  then
    echo "$file"
  else
    echo "$(cd "$(dirname "$file")" && pwd)/$(basename "$file")"
  fi
}

# Internal: source given file or exits with message on error
#
# **Arguments**:
# * $1 file to source
#
# **Exit**: code 1 if error while sourcing
Framework::WrapSource() {
  local libPath="$1"
  shift
  if [[ -z "${libPath}" ]]; then
    return
  fi


  builtin source "$libPath" "$@" || Log::fatal "Unable to load $libPath"
}

# Internal: source given file. Do not source it again if it has already been sourced.
#
# **Arguments**:
# * $1 file to source
#
# **Exit**: code 1 if error while sourcing
Framework::SourceFile() {
  local libPath="$1"
  shift
  if [[ -z "${libPath}" ]]; then
    return
  fi

  [[ ! -f "$libPath" ]] && return 1 # && e="Cannot import $libPath" throw

  libPath="$(Framework::GetAbsolutePath "$libPath")"

  # [ -e "$libPath" ] && echo "Trying to load from: ${libPath}"
  if [[ -f "$libPath" ]]
  then
    ## if already imported let's return
    # if declare -f "Array::contains" &> /dev/null &&
    if [[ "${__bash_framework__allowFileReloading-}" != true && -n "${__bash_framework__importedFiles[*]}" ]] && Array::contains "$libPath" "${__bash_framework__importedFiles[@]}"
    then
      # DEBUG subject=level3 Log "File previously imported: ${libPath}"
      return 0
    fi

    # DEBUG subject=level2 Log "Importing: $libPath"

    __bash_framework__importedFiles+=( "$libPath" )
    Framework::WrapSource "$libPath" "$@"

  else
    :
    # DEBUG subject=level2 Log "File doesn't exist when importing: $libPath"
  fi
}

# Internal: source given file.
# Do not source it again if it has already been sourced.
# try to source relative path from each libpath
#
# **Arguments**:
# * $1 file to source
#
# **Exit**: code 1 if error while sourcing
Framework::SourcePath() {
  local libPath="$1"
  shift
  if [[ -z "${libPath}" ]]; then
    return
  fi

  # echo trying $libPath
  if [[ -d "$libPath" ]]
  then
    local file
    for file in "$libPath"/*.sh
    do
      Framework::SourceFile "$file" "$@"
    done
  else
    Framework::SourceFile "$libPath" "$@" || Framework::SourceFile "${libPath}.sh" "$@"
  fi
}

# Public: source given file.
# Do not source it again if it has already been sourced.
# try to source relative path from each libpath in this order:
# * vendor/bash-framework
# * vendor
# * calling script path
# * absolute path
#
# **Arguments**:
# * $1 file to source
#
# **Exit**: code 1 if error while sourcing
Framework::ImportOne() {
  local libPath="$1"
  shift
  if [[ -z "${libPath}" ]]; then
    return
  fi

  # absolute file
  if [[ "${libPath}" == /* ]]; then
    Framework::SourcePath "${libPath}" "$@"
  else
    # try local library
    # try vendor dir
    # try from project root
    # try absolute path
    {
      local localPath="${__bash_framework_rootVendorPath}"
      localPath="${localPath}/${libPath}"
      Framework::SourcePath "${localPath}" "$@"
    } || \
    Framework::SourcePath "${__bash_framework_rootVendorPath}/${libPath}" "$@" || \
    Framework::SourcePath "${__bash_framework_rootCallingScriptPath}/${libPath}" "$@" || \
    Framework::SourcePath "${libPath}" "$@" || Log::fatal "Cannot import $libPath"
  fi
}

# Public: source given files using Framework::ImportOne.
#
# **Arguments**:
# * $@ files to source
#
# **Exit**: code 1 if error while sourcing
Framework::Import() {
  local savedOptions
  case $- in
  (*x*) savedOptions='set -x'; set +x;;
  (*) savedOptions='';;
  esac
  local libPath
  for libPath in "$@"
  do
    Framework::ImportOne "$libPath"
  done
  { eval "${savedOptions}";} 2> /dev/null
}
