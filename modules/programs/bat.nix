{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.bat;

in {
  meta.maintainers = [ maintainers.marsam ];

  options.programs.bat = {
    enable = mkEnableOption "bat, a cat clone with wings";

    config = mkOption {
      type = types.attrsOf types.str;
      default = { };
      example = {
        theme = "TwoDark";
        pager = "less -FR";
      };
      description = ''
        Bat configuration.
      '';
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.bat ];

    xdg.configFile."bat/config" = mkIf (cfg.config != { }) {
      text = concatStringsSep "\n"
        (mapAttrsToList (n: v: ''--${n}="${v}"'') cfg.config);
    };
  };
}
