{ config, ... }:

{
  time = "2025-11-25T15:00:00+00:00";
  condition = config.programs.codex.enable;
  message = ''
    programs.codex now targets Codex >= 0.2.0 and always writes config.toml.

    YAML (<0.2.0) support was removed; set programs.codex.package accordingly if you need a newer build.
  '';
}
