{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bashmount;

in {
  meta.maintainers = [ maintainers.AndersonTorres ];

  options.programs.bashmount = {
    enable = mkEnableOption "bashmount";

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/bashmount/config</filename>. Look at
        <link xlink:href="https://github.com/jamielinux/bashmount/blob/master/bashmount.conf" />
        for explanation about possible values.
      '';
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.bashmount ];

    xdg.configFile."bashmount/config" =
      mkIf (cfg.extraConfig != "") { text = cfg.extraConfig; };
  };
}
