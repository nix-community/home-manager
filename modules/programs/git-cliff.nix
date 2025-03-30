{ config, lib, pkgs, ... }:
let
  cfg = config.programs.git-cliff;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = [ lib.hm.maintainers.NateCox ];

  options.programs.git-cliff = {
    enable = lib.mkEnableOption "git-cliff changelog generator";

    package = lib.mkPackageOption pkgs "git-cliff" { nullable = true; };

    settings = lib.mkOption {
      type = tomlFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          header = "Changelog";
          trim = true;
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/git-cliff/cliff.toml`. See
        <https://git-cliff.org/docs/configuration>
        for the documentation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "git-cliff/cliff.toml" = lib.mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "git-cliff-config" cfg.settings;
      };
    };
  };
}
