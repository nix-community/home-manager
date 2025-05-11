{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib) mkIf;
  cfg = config.programs.numbat;
  tomlFormat = pkgs.formats.toml { };
  configDir =
    if pkgs.stdenv.hostPlatform.isDarwin then
      "Library/Application Support/numbat"
    else
      "${config.xdg.configHome}/numbat";
in
{
  meta.maintainers = with lib.hm.maintainers; [
    Aehmlo
  ];

  options.programs.numbat = {
    enable = lib.mkEnableOption "Numbat";

    package = lib.mkPackageOption pkgs "numbat" { nullable = true; };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = {
        intro-banner = "short";
        prompt = "> ";
        exchange-rates.fetching-policy = "on-first-use";
      };
      description = ''
        Options to add to {file}`config.toml`. See
        <https://numbat.dev/doc/cli-customization.html#configuration> for options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file."${configDir}/config.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "numbat-config" cfg.settings;
    };
  };
}
