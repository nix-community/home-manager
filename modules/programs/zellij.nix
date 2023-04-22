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
          themes.custom.fg = "#ffffff";
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

    # Zellij switched from yaml to KDL in version 0.32.0:
    # https://github.com/zellij-org/zellij/releases/tag/v0.32.0
    xdg.configFile."zellij/config.yaml" = mkIf
      (cfg.settings != { } && (versionOlder cfg.package.version "0.32.0")) {
        source = yamlFormat.generate "zellij.yaml" cfg.settings;
      };

    xdg.configFile."zellij/config.kdl" = mkIf
      (cfg.settings != { } && (versionAtLeast cfg.package.version "0.32.0")) {
        text = lib.hm.generators.toKDL { } cfg.settings;
      };
  };
}
