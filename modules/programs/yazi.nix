{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.yazi;
  tomlFormat = pkgs.formats.toml { };

  bashIntegration = ''
    function ${cfg.shellWrapperName}() {
      local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
      yazi "$@" --cwd-file="$tmp"
      if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
        builtin cd -- "$cwd"
      fi
      rm -f -- "$tmp"
    }
  '';

  fishIntegration = ''
    function ${cfg.shellWrapperName}
      set tmp (mktemp -t "yazi-cwd.XXXXX")
      yazi $argv --cwd-file="$tmp"
      if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
        builtin cd -- "$cwd"
      end
      rm -f -- "$tmp"
    end
  '';

  nushellIntegration = ''
    def --env ${cfg.shellWrapperName} [...args] {
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
  meta.maintainers = with maintainers; [ xyenon eljamm ];

  options.programs.yazi = {
    enable = mkEnableOption "yazi";

    package = mkPackageOption pkgs "yazi" { };

    shellWrapperName = mkOption {
      type = types.str;
      default = "yy";
      example = "y";
      description = ''
        Name of the shell wrapper to be called.
      '';
    };

    enableBashIntegration = mkEnableOption "Bash integration" // {
      default = true;
    };

    enableZshIntegration = mkEnableOption "Zsh integration" // {
      default = true;
    };

    enableFishIntegration = mkEnableOption "Fish integration" // {
      default = true;
    };

    enableNushellIntegration = mkEnableOption "Nushell integration" // {
      default = true;
    };

    keymap = mkOption {
      type = tomlFormat.type;
      default = { };
      example = literalExpression ''
        {
          input.prepend_keymap = [
            { run = "close"; on = [ "<C-q>" ]; }
            { run = "close --submit"; on = [ "<Enter>" ]; }
            { run = "escape"; on = [ "<Esc>" ]; }
            { run = "backspace"; on = [ "<Backspace>" ]; }
          ];
          manager.prepend_keymap = [
            { run = "escape"; on = [ "<Esc>" ]; }
            { run = "quit"; on = [ "q" ]; }
            { run = "close"; on = [ "<C-q>" ]; }
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
      type = with types; nullOr (either path lines);
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
        Values should be a package or path containing an `init.lua` file.
        Will be linked to {file}`$XDG_CONFIG_HOME/yazi/plugins/<name>.yazi`.

        See <https://yazi-rs.github.io/docs/plugins/overview>
        for documentation.
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
        Values should be a package or path containing the required files.
        Will be linked to {file}`$XDG_CONFIG_HOME/yazi/flavors/<name>.yazi`.

        See <https://yazi-rs.github.io/docs/flavors/overview/> for documentation.
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
      "yazi/init.lua" = mkIf (cfg.initLua != null)
        (if builtins.isPath cfg.initLua then {
          source = cfg.initLua;
        } else {
          text = cfg.initLua;
        });
    } // (mapAttrs' (name: value:
      nameValuePair "yazi/flavors/${name}.yazi" { source = value; })
      cfg.flavors) // (mapAttrs' (name: value:
        nameValuePair "yazi/plugins/${name}.yazi" { source = value; })
        cfg.plugins);

    warnings = filter (s: s != "") (concatLists [
      (mapAttrsToList (name: value:
        optionalString (hasSuffix ".yazi" name) ''
          Flavors like `programs.yazi.flavors."${name}"` should no longer have the suffix ".yazi" in their attribute name.
          The flavor will be linked to `$XDG_CONFIG_HOME/yazi/flavors/${name}.yazi`.
          You probably want to rename it to `programs.yazi.flavors."${
            removeSuffix ".yazi" name
          }"`.
        '') cfg.flavors)
      (mapAttrsToList (name: value:
        optionalString (hasSuffix ".yazi" name) ''
          Plugins like `programs.yazi.plugins."${name}"` should no longer have the suffix ".yazi" in their attribute name.
          The plugin will be linked to `$XDG_CONFIG_HOME/yazi/plugins/${name}.yazi`.
          You probably want to rename it to `programs.yazi.plugins."${
            removeSuffix ".yazi" name
          }"`.
        '') cfg.plugins)
    ]);

    assertions = let
      mkAsserts = opt: requiredFiles:
        mapAttrsToList (name: value:
          let
            isDir = pathIsDirectory "${value}";
            msgNotDir = optionalString (!isDir)
              "The path or package should be a directory, not a single file.";
            isFileMissing = file:
              !(pathExists "${value}/${file}")
              || pathIsDirectory "${value}/${file}";
            missingFiles = filter isFileMissing requiredFiles;
            msgFilesMissing = optionalString (missingFiles != [ ])
              "The ${singularOpt} is missing these files: ${
                toString missingFiles
              }";
            singularOpt = removeSuffix "s" opt;
          in {
            assertion = isDir && missingFiles == [ ];
            message = ''
              Value at `programs.yazi.${opt}.${name}` is not a valid yazi ${singularOpt}.
              ${msgNotDir}
              ${msgFilesMissing}
              Evaluated value: `${value}`
            '';
          }) cfg.${opt};
    in (mkAsserts "flavors" [
      "flavor.toml"
      "tmtheme.xml"
      "README.md"
      "preview.png"
      "LICENSE"
      "LICENSE-tmtheme"
    ]) ++ (mkAsserts "plugins" [ "init.lua" ]);
  };
}
