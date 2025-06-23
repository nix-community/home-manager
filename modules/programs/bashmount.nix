{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.bashmount;
in
{
  meta.maintainers = [ lib.maintainers.AndersonTorres ];

  options.programs.bashmount = {
    enable = lib.mkEnableOption "bashmount";

    package = lib.mkPackageOption pkgs "bashmount" { nullable = true; };

    extraConfig = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/bashmount/config`. Look at
        <https://github.com/jamielinux/bashmount/blob/master/bashmount.conf>
        for explanation about possible values.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."bashmount/config" = lib.mkIf (cfg.extraConfig != "") { text = cfg.extraConfig; };
  };
}
