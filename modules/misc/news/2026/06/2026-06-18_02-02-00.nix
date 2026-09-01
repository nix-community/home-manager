{ config, pkgs, ... }:

{
  time = "2026-06-18T02:02:00+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin && config.launchd.enable;
  message = ''

    Home Manager launchd agents now support the
    `launchd.agents.<name>.domain` option. Agents use the GUI launchd domain by
    default. Set `launchd.agents.<name>.domain = "user"` for agents that should
    run without an active graphical login session.
  '';
}
