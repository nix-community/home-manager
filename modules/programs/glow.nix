{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.glow;
  yamlFormat = pkgs.formats.yaml { };
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in
{
  meta.maintainers = [ hm.maintainers.m-vz ];

  options.programs.glow = {
    enable = mkEnableOption "Glow, a terminal based markdown reader";

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = literalExpression ''
        {
          # style name or JSON path (default "auto")
          style = "auto";
          # mouse support (TUI-mode only)
          mouse = false;
          # use pager to display markdown
          pager = false;
          # word-wrap at width
          width = 80;
          # show all files, including hidden and ignored.
          all = false;
        }
      '';
      description = ''
        Configuration written to `~/.config/glow/glow.yml` on Linux
        or `~/Library/Preferences/glow/glow.yml` on Darwin.
        See <https://github.com/charmbracelet/glow#the-config-file>
        for supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.glow ];

    home.file."Library/Preferences/glow/glow.yml" = mkIf (cfg.settings != { } && isDarwin) {
      source = yamlFormat.generate "glow.yml" cfg.settings;
    };

    xdg.configFile."glow/glow.yml" = mkIf (cfg.settings != { } && !isDarwin) {
      source = yamlFormat.generate "glow.yml" cfg.settings;
    };
  };
}
