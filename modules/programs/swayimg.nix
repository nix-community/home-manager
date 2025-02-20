{ pkgs, config, lib, ... }:
let
  cfg = config.programs.swayimg;
  iniFormat = pkgs.formats.ini { };
in {
  meta.maintainers = [ lib.maintainers.adtya ];

  options.programs.swayimg = {
    enable = lib.mkEnableOption "swayimg";
    package = lib.mkPackageOption pkgs "swayimg" { };
    settings = lib.mkOption {
      type = iniFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          general = {
            scale = "optimal";
            fullscreen = "no";
          };
        };
      '';
      description = ''
        Configuration written to {file}`$XDG_CONFIG_HOME/swayimg/config`. See
        {manpage}`swayimgrc(5)` for a list of available options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.swayimg" pkgs
        lib.platforms.linux)
    ];
    home.packages = [ cfg.package ];
    xdg.configFile."swayimg/config" = lib.mkIf (cfg.settings != { }) {
      text = lib.generators.toINI { } cfg.settings;
    };
  };
}
