{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.micro;

  jsonFormat = pkgs.formats.json { };

in {
  meta.maintainers = [ hm.maintainers.mforster ];

  options = {
    programs.micro = {
      enable = mkEnableOption "micro, a terminal-based text editor";

      settings = mkOption {
        type = jsonFormat.type;
        default = { };
        example = literalExpression ''
          {
            autosu = false;
            cursorline = false;
          }
        '';
        description = ''
          Configuration written to
          <filename>$XDG_CONFIG_HOME/micro/settings.json</filename>. See
          <link xlink:href="https://github.com/zyedidia/micro/blob/master/runtime/help/options.md"/>
          for supported values.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.micro ];

    xdg.configFile."micro/settings.json".source =
      jsonFormat.generate "micro-settings" cfg.settings;
  };
}
