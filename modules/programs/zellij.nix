{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.zellij;
  yamlFormat = pkgs.formats.yaml { };

in {
  meta.maintainers = [ hm.maintainers.mainrs ];

  options.programs.zellij = {
    enable = mkEnableOption "zellij";

    package = mkOption {
      type = types.package;
      default = pkgs.zellij;
      defaultText = literalExpression "pkgs.zellij";
      description = ''
        The zellij package to install.
      '';
    };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = literalExpression ''
        {
          theme = "custom";
          themes.custom.fg = 5;
        }
      '';
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/zellij/config.yaml</filename>.
        </para><para>
        See <link xlink:href="https://zellij.dev/documentation" /> for the full
        list of options.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."zellij/config.yaml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "zellij.yaml" cfg.settings;
    };
  };
}
