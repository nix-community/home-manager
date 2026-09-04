{ config, ... }:
{
  time = "2026-09-03T20:42:31+00:00";
  condition = config.programs.obs-studio.enable;
  message = ''
    `programs.obs-studio` can now manage global and user settings, profiles,
    scene collections, and plugin configuration. See the new
    `programs.obs-studio.settings`, `programs.obs-studio.profiles`,
    `programs.obs-studio.sceneCollections`,
    `programs.obs-studio.integrations`, and
    `programs.obs-studio.extraConfigFiles` options.

    These files remain writable for OBS Studio, but Home Manager replaces
    declared files during activation and removes files that are no longer
    declared. Files created independently by OBS Studio remain untouched.
  '';
}
