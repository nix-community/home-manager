{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.lazygit;

  yamlFormat = pkgs.formats.yaml { };

  inherit (pkgs.stdenv.hostPlatform) isDarwin;

in {
  meta.maintainers = [ maintainers.kalhauge ];

  options.programs.lazygit = {
    enable = mkEnableOption "lazygit, a simple terminal UI for git commands";

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
        <filename>~/.config/lazygit/config.yml</filename> on Linux
        or <filename>~/Library/Application Support/lazygit/config.yml</filename> on Darwin. See
        <link xlink:href="https://github.com/jesseduffield/lazygit/blob/master/docs/Config.md"/>
        for supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.lazygit ];

    home.file."Library/Application Support/lazygit/config.yml" =
      mkIf (cfg.settings != { } && isDarwin) {
        source = yamlFormat.generate "lazygit-config" cfg.settings;
      };

    xdg.configFile."lazygit/config.yml" =
      mkIf (cfg.settings != { } && !isDarwin) {
        source = yamlFormat.generate "lazygit-config" cfg.settings;
      };
  };
}
