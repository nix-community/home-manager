{ config, lib, pkgs, ... }:
let cfg = config.programs.less;
in {
  meta.maintainers = [ lib.maintainers.pamplemousse ];

  options = {
    programs.less = {
      enable = lib.mkEnableOption "less, opposite of more";

      keys = lib.mkOption {
        type = lib.types.lines;
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

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.less ];
    xdg.configFile."lesskey".text = cfg.keys;
  };
}
