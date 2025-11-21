{ pkgs, ... }:

{
  time = "2022-02-26T09:28:57+00:00";
  condition = pkgs.stdenv.hostPlatform.isDarwin;
  message = ''

    A new module is available: 'launchd.agents'

    Use this to enable services based on macOS LaunchAgents.
  '';
}
