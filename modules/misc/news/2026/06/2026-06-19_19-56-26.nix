{ config, ... }:
{
  time = "2026-06-19T19:56:26+00:00";
  condition = config.fonts.fontconfig.enable;
  message = ''
    There is a new `fonts.fontconfig.packages` option to add font packages
    directly to Fontconfig's search paths. This can be useful for fonts that
    need deterministic discovery through immutable store paths rather than the
    Home Manager profile.
  '';
}
