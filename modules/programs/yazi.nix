{ config, lib, pkgs, ... }:
let
  inherit (lib)
    literalExpression mapAttrsToList mkEnableOption mkIf mkOption optionalString
    types;

  cfg = config.programs.yazi;
  tomlFormat = pkgs.formats.toml { };
in {
  meta.maintainers = with lib.maintainers; [ eljamm khaneliman xyenon ];

  options.programs.yazi = {
    enable = mkEnableOption "yazi";

    package = lib.mkPackageOption pkgs "yazi" { };

    shellWrapperName = lib.mkOption {
      type = types.str;
      default = "yy";
      example = "y";
      description = ''
        Name of the shell wrapper to be called.
      '';
    };

    enableBashIntegration =
      lib.hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration =
      lib.hm.shell.mkFishIntegrationOption { inherit config; };

    enableNushellIntegration =
      lib.hm.shell.mkNushellIntegrationOption { inherit config; };

    enableZshIntegration =
      lib.hm.shell.mkZshIntegrationOption { inherit config; };

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
            sort_by = "mtime";
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
              { fg = "#CD9EFC"; mime = "application/bzip"; }
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

    programs = let
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
        set -l tmp (mktemp -t "yazi-cwd.XXXXX")
        command yazi $argv --cwd-file="$tmp"
        if set cwd (cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
          builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
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
      bash.initExtra = mkIf cfg.enableBashIntegration bashIntegration;

      zsh.initExtra = mkIf cfg.enableZshIntegration bashIntegration;

      fish.functions.${cfg.shellWrapperName} =
        mkIf cfg.enableFishIntegration fishIntegration;

      nushell.extraConfig =
        mkIf cfg.enableNushellIntegration nushellIntegration;
    };

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
    } // (lib.mapAttrs' (name: value:
      lib.nameValuePair "yazi/flavors/${name}.yazi" { source = value; })
      cfg.flavors) // (lib.mapAttrs' (name: value:
        lib.nameValuePair "yazi/plugins/${name}.yazi" { source = value; })
        cfg.plugins);

    warnings = lib.filter (s: s != "") (lib.concatLists [
      (mapAttrsToList (name: _value:
        optionalString (lib.hasSuffix ".yazi" name) ''
          Flavors like `programs.yazi.flavors."${name}"` should no longer have the suffix ".yazi" in their attribute name.
          The flavor will be linked to `$XDG_CONFIG_HOME/yazi/flavors/${name}.yazi`.
          You probably want to rename it to `programs.yazi.flavors."${
            lib.removeSuffix ".yazi" name
          }"`.
        '') cfg.flavors)
      (mapAttrsToList (name: _value:
        optionalString (lib.hasSuffix ".yazi" name) ''
          Plugins like `programs.yazi.plugins."${name}"` should no longer have the suffix ".yazi" in their attribute name.
          The plugin will be linked to `$XDG_CONFIG_HOME/yazi/plugins/${name}.yazi`.
          You probably want to rename it to `programs.yazi.plugins."${
            lib.removeSuffix ".yazi" name
          }"`.
        '') cfg.plugins)
    ]);

    assertions = let
      mkAsserts = opt: requiredFiles:
        mapAttrsToList (name: value:
          let
            isDir = lib.pathIsDirectory "${value}";
            msgNotDir = optionalString (!isDir)
              "The path or package should be a directory, not a single file.";
            isFileMissing = file:
              !(lib.pathExists "${value}/${file}")
              || lib.pathIsDirectory "${value}/${file}";
            missingFiles = lib.filter isFileMissing requiredFiles;
            msgFilesMissing = optionalString (missingFiles != [ ])
              "The ${singularOpt} is missing these files: ${
                toString missingFiles
              }";
            singularOpt = lib.removeSuffix "s" opt;
            isPluginValid = opt == "plugins"
              && (lib.any (file: lib.pathExists "${value}/${file}")
                requiredFiles);
            isValid =
              if opt == "plugins" then isPluginValid else missingFiles == [ ];
          in {
            assertion = isDir && isValid;
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
    ]) ++ (mkAsserts "plugins" [ "init.lua" "main.lua" ]);
  };
}
