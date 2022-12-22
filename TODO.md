# Todo

- add https://github.com/fchastanet/bash-tools in help of each command
- refact buildPushDockerImages/runBuildContainer so it is independent of
  bash-tools
- dbImportStream ability to import from dbAuthFile internally or from db
  parameters
- migrate jekyll to <https://nextra.site/docs/guide/organize-files> ?

  - copy jekyll conf
  - check if all variable = are declared local

- Update libraries command

  - command that allows to update the libraries in the repo
  - github cron that checks if library updates exists

- linter that checks if namespace::function exist in lib directory
- import ck_ip_dev_env commands
- new function Env::get "HOME"
  - eg: Env::get "HOME" will get HOME variable from .env file if exists or get
    global HOME variable
  - replace all ${HOME} by $(Env::get "HOME")
  - generate automatically .env.template from Env::get
- src/build/install.sh use backupDir
- <https://github.com/adoyle-h/lobash>
- <https://github.com/elibs/ebash>
- <https://pre-commit.ci/> I don't understand where the code is executed if not
  using lite version
- add code coverage <https://github.com/SimonKagstrom/kcov>
  - upload code coverage to deepsource using github action
