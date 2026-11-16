{ config, ... }:
{
  time = "2026-10-08T08:39:26+00:00";
  condition = config.programs.herdr.enable;
  message = ''
    The Herdr module now supports mutable user settings through
    `programs.herdr.mutableSettings`.

    When enabled, Home Manager merges declared settings into Herdr's existing
    `config.toml` during activation. Declared values take precedence, while
    settings added through Herdr or edited by hand are preserved. This option
    defaults to `false`, so settings remain immutable unless you opt in.
  '';
}
