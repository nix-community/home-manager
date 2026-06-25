{ config, pkgs, ... }:

{
  time = "2026-06-18T02:02:00+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin && config.launchd.enable;
  message = ''

    Home Manager launchd agents now support the
    `launchd.agents.<name>.domain` option. Background services provided by Home
    Manager use the user launchd domain by default, so they can be managed from
    SSH and other non-graphical sessions. Set
    `launchd.agents.<name>.domain = "gui"` for agents that need the graphical
    session.
  '';
}
