{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    hm
    mkEnableOption
    mkIf
    mkOption
    ;
  cfg = config.programs.sheldon;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with hm.maintainers; [
    Kyure-A
    mainrs
    elanora96
  ];

  options.programs.sheldon = {
    enable = mkEnableOption "sheldon";

    package = lib.mkPackageOption pkgs "sheldon" { };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = "";
      example = lib.literalExpression "";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."sheldon/plugins.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "sheldon-config" cfg.settings;
    };
  };
}
