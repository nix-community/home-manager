{ config, pkgs, lib, ... }:
let cfg = config.programs.script-directory;
in {
  meta.maintainers = [ lib.maintainers.janik ];

  options.programs.script-directory = {
    enable = lib.mkEnableOption "script-directory";

    package = lib.mkPackageOption pkgs "script-directory" { };

    settings = lib.mkOption {
      default = { };
      type = lib.types.attrsOf lib.types.str;
      example = lib.literalExpression ''
        {
          SD_ROOT = "''${config.home.homeDirectory}/.sd";
          SD_EDITOR = "nvim";
          SD_CAT = "lolcat";
        }
      '';
      description =
        "script-directory config, for options take a look at the [documentation](https://github.com/ianthehenry/sd#options)";
    };
  };
  config = lib.mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];
      sessionVariables = cfg.settings;
    };
  };
}
