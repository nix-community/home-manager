{ config, ... }:
{
  time = "2026-09-21T00:00:00+00:00";
  condition = config.programs.borgmatic.enable;
  message = ''
    Borgmatic backups now use `programs.borgmatic.backups.<name>.settings`
    for native YAML settings. Legacy `location`, `storage`, `retention`, and
    `consistency` options (except `location.excludeHomeManagerSymlinks`) and
    the six `extraConfig` options remain as deprecated aliases and warn when
    used. Move their values into `settings`.
  '';
}
