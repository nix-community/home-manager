{ config, lib, ... }:
{
  time = "2026-10-20T03:59:59+00:00";
  condition =
    config.programs.gradle.enable
    && config.home.preferXdgDirectories
    &&
      config.programs.gradle.home
      == lib.removePrefix "${config.home.homeDirectory}/" "${config.xdg.dataHome}/gradle";
  message = ''
    `programs.gradle.home` now defaults to
    `${config.xdg.dataHome}/gradle` when
    `home.preferXdgDirectories` is true and `home.stateVersion` is at
    least 26.11.

    Existing Gradle data in `~/.gradle` is not migrated automatically. Move it
    to the new directory, or preserve the previous behavior with:

      programs.gradle.home = ".gradle";
  '';
}
