{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.eww;

in {
  meta.maintainers = [ hm.maintainers.mainrs ];

  options.programs.eww = {
    enable = mkEnableOption "eww";

    package = mkOption {
      type = types.package;
      default = pkgs.eww;
      defaultText = literalExpression "pkgs.eww";
      example = literalExpression "pkgs.eww";
      description = ''
        The eww package to install.
      '';
    };

    configYuck = mkOption {
      type = types.lines;
      example = literalExpression ''
        (defwindow example
             :monitor 0
             :geometry (geometry :x "0%"
                                 :y "20px"
                                 :width "90%"
                                 :height "30px"
                                 :anchor "top center")
             :stacking "fg"
             :reserve (struts :distance "40px" :side "top")
             :windowtype "dock"
             :wm-ignore false
          "example content")
      '';
      description = ''
        The content that gets symlinked to
        {file} `$XDG_CONFIG_HOME/eww/eww.yuck`.
      '';
    };

    configScss = mkOption {
      type = types.lines;
      example = literalExpression ''
        window {
          background: pink;
        }
      '';
      description = ''
        The content that gets symlinked to
        {file} `$XDG_CONFIG_HOME/eww/eww.scss`
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile = {
      "eww/eww.yuck".text = cfg.configYuck;
      "eww/eww.scss".text = cfg.configScss;
    };
  };
}

