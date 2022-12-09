# Todo

- build.sh move md5 computation from build.sh to workflow script
- merge buildDoc.sh and doc.sh
- doc.sh move bash-framework doc generation to bash-tools-framework
- migrate jekyll to <https://nextra.site/docs/guide/organize-files> ?
- Bash-tools only contains commands, build tools (linters, ...)

  - move build.sh to bin/build
  - copy jekyll conf
  - check if all variable = are declared local

- generate github page from Readme.tmpl.md using github workflow
  - include bin help
  - include bash doc
- cat << EOF avoid to interpolate variables
- Update libraries command

  - command that allows to update the libraries in the repo
  - github cron that checks if library updates exists

- Refact
  - check all functions calls exists
  - ensure we don't have any globals, all variables should be passed to the
    functions
- add build.sh in precommit hook
- linter that checks if namespace::function exist in lib directory
- support nested namespace
- import bash-tools commands + libs
- import ck_ip_dev_env commands
- fix github actions scripts
- add megalinter <https://github.com/marketplace/actions/megalinter>
- new function Env::get "HOME"
  - eg: Env::get "HOME" will get HOME variable from .env file if exists or get
    global HOME variable
  - replace all ${HOME} by $(Env::get "HOME")
  - generate automatically .env.template from Env::get
- src/build/install.sh use backupDir
- <https://dougrichardson.us/notes/fail-fast-bash-scripting.html>
- <https://github.com/adoyle-h/lobash>
- <https://github.com/elibs/ebash>
- <https://github.com/pre-commit/action>