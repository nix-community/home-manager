{ config, ... }:
{
  time = "2026-09-27T21:57:36+00:00";
  condition = config.programs.codex.enable;
  message = ''
    The Codex module now supports mutable user settings through
    `programs.codex.mutableSettings`.

    When enabled, Home Manager merges declared settings into Codex's existing
    `config.toml` during activation. Declared values take precedence, while
    settings added through Codex or edited by hand are preserved. This option
    requires Codex 0.2.0 or later and defaults to `false`, so settings remain
    immutable unless you opt in.
  '';
}
