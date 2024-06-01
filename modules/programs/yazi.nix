{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.yazi;
  tomlFormat = pkgs.formats.toml { };

  bashIntegration = ''
    function ya() {
      local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
      yazi "$@" --cwd-file="$tmp"
      if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
      fi
      rm -f -- "$tmp"
    }
  '';

  fishIntegration = ''
    function ya
      set tmp (mktemp -t "yazi-cwd.XXXXX")
      yazi $argv --cwd-file="$tmp"
      if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
      end
      rm -f -- "$tmp"
    end
  '';

  nushellIntegration = ''
    def --env ya [...args] {
      let tmp = (mktemp -t "yazi-cwd.XXXXX")
      yazi ...$args --cwd-file $tmp
      let cwd = (open $tmp)
      if $cwd != "" and $cwd != $env.PWD {
        cd $cwd
      }
      rm -fp $tmp
    }
  '';
in {
  meta.maintainers = with maintainers; [ xyenon ];

  options.programs.yazi = {
    enable = mkEnableOption "yazi";

    package = mkPackageOption pkgs "yazi" { };

    enableBashIntegration = mkEnableOption "Bash integration";

    enableZshIntegration = mkEnableOption "Zsh integration";

    enableFishIntegration = mkEnableOption "Fish integration";

    enableNushellIntegration = mkEnableOption "Nushell integration";

    keymap = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          input.keymap = [
            { exec = "close"; on = [ "<C-q>" ]; }
            { exec = "close --submit"; on = [ "<Enter>" ]; }
            { exec = "escape"; on = [ "<Esc>" ]; }
            { exec = "backspace"; on = [ "<Backspace>" ]; }
          ];
          manager.keymap = [
            { exec = "escape"; on = [ "<Esc>" ]; }
            { exec = "quit"; on = [ "q" ]; }
            { exec = "close"; on = [ "<C-q>" ]; }
          ];
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/yazi/keymap.toml`.

        See <https://yazi-rs.github.io/docs/configuration/keymap>
        for the full list of options.
      '';
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          log = {
            enabled = false;
          };
          manager = {
            show_hidden = false;
            sort_by = "modified";
            sort_dir_first = true;
            sort_reverse = true;
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/yazi/yazi.toml`.

        See <https://yazi-rs.github.io/docs/configuration/yazi>
        for the full list of options.
      '';
    };

    theme = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          filetype = {
            rules = [
              { fg = "#7AD9E5"; mime = "image/*"; }
              { fg = "#F3D398"; mime = "video/*"; }
              { fg = "#F3D398"; mime = "audio/*"; }
              { fg = "#CD9EFC"; mime = "application/x-bzip"; }
            ];
          };
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/yazi/theme.toml`.

        See <https://yazi-rs.github.io/docs/configuration/theme>
        for the full list of options
      '';
    };

    initLua = mkOption {
      type = with types; nullOr path;
      default = null;
      description = ''
        The init.lua for Yazi itself.
      '';
      example = literalExpression "./init.lua";
    };

    plugins = mkOption {
      type = with types; attrsOf (oneOf [ path package ]);
      default = { };
      description = ''
        Lua plugins.

        See https://yazi-rs.github.io/docs/plugins/overview/ for documentation.
      '';
      example = literalExpression ''
        {
          foo = ./foo;
          bar = pkgs.bar;
        }
      '';
    };

    flavors = mkOption {
      type = with types; attrsOf (oneOf [ path package ]);
      default = { };
      description = ''
        Pre-made themes.

        See https://yazi-rs.github.io/docs/flavors/overview/ for documentation.
      '';
      example = literalExpression ''
        {
          foo = ./foo;
          bar = pkgs.bar;
        }
      '';
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.bash.initExtra = mkIf cfg.enableBashIntegration bashIntegration;

    programs.zsh.initExtra = mkIf cfg.enableZshIntegration bashIntegration;

    programs.fish.interactiveShellInit =
      mkIf cfg.enableFishIntegration fishIntegration;

    programs.nushell.extraConfig =
      mkIf cfg.enableNushellIntegration nushellIntegration;

    xdg.configFile = {
      "yazi/keymap.toml" = mkIf (cfg.keymap != { }) {
        source = tomlFormat.generate "yazi-keymap" cfg.keymap;
      };
      "yazi/yazi.toml" = mkIf (cfg.settings != { }) {
        source = tomlFormat.generate "yazi-settings" cfg.settings;
      };
      "yazi/theme.toml" = mkIf (cfg.theme != { }) {
        source = tomlFormat.generate "yazi-theme" cfg.theme;
      };
      "yazi/init.lua" = mkIf (cfg.initLua != null) { source = cfg.initLua; };
    } // (mapAttrs'
      (name: value: nameValuePair "yazi/plugins/${name}" { source = value; })
      cfg.plugins) // (mapAttrs'
        (name: value: nameValuePair "yazi/flavors/${name}" { source = value; })
        cfg.flavors);
  };
}
