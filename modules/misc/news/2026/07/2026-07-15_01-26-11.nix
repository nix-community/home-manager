{ pkgs, ... }:
{
  time = "2026-07-15T00:26:11+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''
    A new option is available: 'launchd.agents.<name>.waitForNixStore'.

    By default, launchd agents are started through a '/bin/sh' wrapper
    that waits for the Nix store to be mounted, which makes every agent
    show up as "sh" in System Settings > Login Items & Extensions. When
    this option is disabled, the agent is instead started through a
    launcher script named after the agent, so it is displayed under its
    own name. Note that disabling it means the agent will fail to start
    if launchd runs it before the Nix store volume is mounted (e.g.
    early during login when the store volume is encrypted).
  '';
}
