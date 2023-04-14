{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.lazygit;

  yamlFormat = pkgs.formats.yaml { };

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

in {
  meta.maintainers = [ hm.maintainers.kalhauge ];

  options.programs.lazygit = {
    enable = mkEnableOption "lazygit, a simple terminal UI for git commands";

    package = mkPackageOption pkgs "lazygit" { };

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      defaultText = literalExpression "{ }";
      example = literalExpression ''
        {
          gui.theme = {
            lightTheme = true;
            activeBorderColor = [ "blue" "bold" ];
            inactiveBorderColor = [ "black" ];
            selectedLineBgColor = [ "default" ];
          };
        }
      '';
      description = ''
        Configuration written to
        <filename>$XDG_CONFIG_HOME/lazygit/config.yml</filename>
        on Linux or on Darwin if <xref linkend="opt-xdg.enable"/> is set, otherwise
        <filename>~/Library/Application Support/lazygit/config.yml</filename>.
        See
        <link xlink:href="https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md"/>
        for supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file."Library/Application Support/lazygit/config.yml" =
      mkIf (cfg.settings != { } && (isDarwin && !config.xdg.enable)) {
        source = yamlFormat.generate "lazygit-config" cfg.settings;
      };

    xdg.configFile."lazygit/config.yml" =
      mkIf (cfg.settings != { } && !(isDarwin && !config.xdg.enable)) {
        source = yamlFormat.generate "lazygit-config" cfg.settings;
      };
  };
}
