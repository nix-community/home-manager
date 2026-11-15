{
  config,
  lib,
  ...
}:
{
  time = "2026-11-15T18:18:17+00:00";
  condition = lib.any (agent: agent.enable && agent.domain == "user") (
    lib.attrValues config.launchd.agents
  );
  message = ''
    On macOS, launchd only loads '~/Library/LaunchAgents' at graphical login.
    Agents configured with 'launchd.agents.<name>.domain = "user"' are now
    bootstrapped at boot by a launchd daemon that the nix-darwin module
    installs, so they no longer need a login session. This daemon does not
    exist when Home Manager runs standalone on macOS.
  '';
}
