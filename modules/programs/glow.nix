{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.glow;
  yamlFormat = pkgs.formats.yaml { };
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in {
  meta.maintainers = [ maintainers.geowy ];

  options.programs.glow = {
    enable = mkEnableOption "Glow, a terminal based markdown reader";

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      defaultText = literalExample "{ }";
      example = literalExample ''
        {
          # style name or JSON path (default "auto")
          style = "light";
          # show local files only; no network (TUI-mode only)
          local = true;
          # mouse support (TUI-mode only)
          mouse = true;
          # use pager to display markdown
          pager = true;
          # word-wrap at width
          width = 80;
        }
      '';
      description = ''
        Configuration written to
        <filename>~/.config/glow/glow.yml</filename> on Linux
        or <filename>~/Library/Preferences/glow/glow.yml</filename> on Darwin. See
        <link xlink:href="https://github.com/charmbracelet/glow#the-config-file"/>
        for supported values.
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [ pkgs.glow ];

      home.file."Library/Preferences/glow/glow.yml" =
        mkIf (cfg.settings != { } && isDarwin) {
          text = builtins.toJSON cfg.settings;
        };

      xdg.configFile."glow/glow.yml" = mkIf (cfg.settings != { } && !isDarwin) {
        text = builtins.toJSON cfg.settings;
      };
    })
  ];
}
