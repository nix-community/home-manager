{ config, ... }:
{
  time = "2025-08-05T19:17:50+00:00";
  condition = config.programs.nh.enable;
  message = ''
    The 'programs.nh' module now supports flake-specific configuration.

    New options allow separate flakes for different nh operations:
    - 'programs.nh.osFlake' - Default flake for 'nh os' commands (NH_OS_FLAKE)
    - 'programs.nh.homeFlake' - Default flake for 'nh home' commands (NH_HOME_FLAKE)

    These options take priority over the general 'flake' option when set.
  '';
}
