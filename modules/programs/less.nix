{ config, lib, pkgs, ... }:

with lib;

let cfg = config.programs.less;
in {
  meta.maintainers = [ maintainers.pamplemousse ];

  options = {
    programs.less = {
      enable = mkEnableOption "less, opposite of more";

      keys = mkOption {
        type = types.lines;
        default = "";
        example = ''
          s        back-line
          t        forw-line
        '';
        description = ''
          Extra configuration for {command}`less` written to
          {file}`$XDG_CONFIG_HOME/lesskey`.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.less ];
    xdg.configFile."lesskey".text = cfg.keys;
  };
}
