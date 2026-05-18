{ config, ... }:

{
  time = "2026-05-18T02:52:12+00:00";
  condition = config.services.elephant.enable;
  message = ''
    A new service is available: 'services.elephant'.

    Elephant is a data provider service for application launchers such as
    Walker. The module can install Elephant, generate
    `~/.config/elephant/config.toml`, and run Elephant as a systemd user
    service.
  '';
}
