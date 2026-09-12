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

    Files use Home Manager's mutable-copy support. Activation replaces OBS
    edits, and removing declarations or disabling OBS deletes the managed
    copies. Existing unmanaged files require a backup or an explicit force
    setting before adoption. Stop OBS before switching generations, and do
    not include secrets in these settings because sources enter the Nix store.
  '';
}
