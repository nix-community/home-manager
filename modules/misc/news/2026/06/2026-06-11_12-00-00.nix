{ config, ... }:
{
  time = "2026-06-11T16:00:00+00:00";
  condition = config.programs.codex.enable;
  message = ''
    The `programs.codex.plugins` and `programs.codex.marketplaces` options
    were added to configure Codex plugins and local plugin marketplaces
    declaratively.
  '';
}
