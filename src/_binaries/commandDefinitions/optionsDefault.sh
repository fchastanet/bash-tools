#!/usr/bin/env bash

defaultBeforeParseCallback() {
  BashTools::Conf::requireLoad
  Env::requireLoad
  UI::requireTheme
  Log::requireLoad
}

beforeParseCallback() {
  defaultBeforeParseCallback
}
