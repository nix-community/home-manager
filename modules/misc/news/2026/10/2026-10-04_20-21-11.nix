{ config, ... }:
{
  time = "2026-10-05T01:21:11+00:00";
  condition = config.programs.jujutsu.enable;
  message = ''
    Jujutsu now supports `programs.jujutsu.mutableSettings` to load
    declarative settings from `jj/conf.d/home-manager.toml`, leaving
    `jj/config.toml` writable. The option is disabled by default and
    requires Jujutsu 0.28 or later, or 0.29 or later on Darwin.
  '';
}
