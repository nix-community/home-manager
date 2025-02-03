{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.kitty;

  settingsValueType = with types; oneOf [ str bool int float ];

  optionalPackage = opt:
    optional (opt != null && opt.package != null) opt.package;

  toKittyConfig = generators.toKeyValue {
    mkKeyValue = key: value:
      let
        value' =
          (if isBool value then lib.hm.booleans.yesNo else toString) value;
      in "${key} ${value'}";
  };

  toKittyKeybindings = generators.toKeyValue {
    mkKeyValue = key: command: "map ${key} ${command}";
  };

  toKittyEnv =
    generators.toKeyValue { mkKeyValue = name: value: "env ${name}=${value}"; };

  shellIntegrationInit = {
    bash = ''
      if test -n "$KITTY_INSTALLATION_DIR"; then
        export KITTY_SHELL_INTEGRATION="${cfg.shellIntegration.mode}"
        source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
      fi
    '';
    fish = ''
      if set -q KITTY_INSTALLATION_DIR
        set --global KITTY_SHELL_INTEGRATION "${cfg.shellIntegration.mode}"
        source "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_conf.d/kitty-shell-integration.fish"
        set --prepend fish_complete_path "$KITTY_INSTALLATION_DIR/shell-integration/fish/vendor_completions.d"
      end
    '';
    zsh = ''
      if test -n "$KITTY_INSTALLATION_DIR"; then
        export KITTY_SHELL_INTEGRATION="${cfg.shellIntegration.mode}"
        autoload -Uz -- "$KITTY_INSTALLATION_DIR"/shell-integration/zsh/kitty-integration
        kitty-integration
        unfunction kitty-integration
      fi
    '';
  };

  shellIntegrationDefaultOpt = {
    default = !(elem "disabled" (splitString " " cfg.shellIntegration.mode));
    defaultText = literalExpression ''
      !(elem "disabled" (splitString " " config.programs.kitty.shellIntegration.mode))
    '';
  };
in {
  imports = [
    (mkChangedOptionModule [ "programs" "kitty" "theme" ] [
      "programs"
      "kitty"
      "themeFile"
    ] (config:
      let value = getAttrFromPath [ "programs" "kitty" "theme" ] config;
      in if value != null then
        (let
          matching = filter (x: x.name == value) (builtins.fromJSON
            (builtins.readFile
              "${pkgs.kitty-themes}/share/kitty-themes/themes.json"));
        in throwIf (length matching == 0)
        "kitty-themes does not contain a theme named ${value}"
        strings.removeSuffix ".conf"
        (strings.removePrefix "themes/" (head matching).file))
      else
        null))
  ];

  options.programs.kitty = {
    enable = mkEnableOption "Kitty terminal emulator";

    package = mkOption {
      type = types.package;
      default = pkgs.kitty;
      defaultText = literalExpression "pkgs.kitty";
      description = ''
        Kitty package to install.
      '';
    };

    darwinLaunchOptions = mkOption {
      type = types.nullOr (types.listOf types.str);
      default = null;
      description = "Command-line options to use when launched by Mac OS GUI";
      example = literalExpression ''
        [
          "--single-instance"
          "--directory=/tmp/my-dir"
          "--listen-on=unix:/tmp/my-socket"
        ]
      '';
    };

    settings = mkOption {
      type = types.attrsOf settingsValueType;
      default = { };
      example = literalExpression ''
        {
          scrollback_lines = 10000;
          enable_audio_bell = false;
          update_check_interval = 0;
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/kitty/kitty.conf`. See
        <https://sw.kovidgoyal.net/kitty/conf.html>
        for the documentation.
      '';
    };

    themeFile = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Apply a Kitty color theme. This option takes the file name of a theme
        in `kitty-themes`, without the `.conf` suffix. See
        <https://github.com/kovidgoyal/kitty-themes/tree/master/themes> for a
        list of themes.
      '';
      example = "SpaceGray_Eighties";
    };

    font = mkOption {
      type = types.nullOr hm.types.fontType;
      default = null;
      description = "The font to use.";
    };

    keybindings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Mapping of keybindings to actions.";
      example = literalExpression ''
        {
          "ctrl+c" = "copy_or_interrupt";
          "ctrl+f>2" = "set_font_size 20";
        }
      '';
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Environment variables to set or override.";
      example = literalExpression ''
        {
          "LS_COLORS" = "1";
        }
      '';
    };

    shellIntegration = {
      mode = mkOption {
        type = types.str;
        default = "no-rc";
        example = "no-cursor";
        apply = o:
          let
            modes = splitString " " o;
            filtered = filter (m: m != "no-rc") modes;
          in concatStringsSep " " (concatLists [ [ "no-rc" ] filtered ]);
        description = ''
          Set the mode of the shell integration. This accepts the same options
          as the `shell_integration` option of Kitty. Note that
          `no-rc` is always implied. See
          <https://sw.kovidgoyal.net/kitty/shell-integration>
          for more details.
        '';
      };

      enableBashIntegration = mkEnableOption "Kitty Bash integration"
        // shellIntegrationDefaultOpt;

      enableFishIntegration = mkEnableOption "Kitty fish integration"
        // shellIntegrationDefaultOpt;

      enableZshIntegration = mkEnableOption "Kitty Z Shell integration"
        // shellIntegrationDefaultOpt;
    };

    extraConfig = mkOption {
      default = "";
      type = types.lines;
      description = "Additional configuration to add.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ] ++ optionalPackage cfg.font;

    xdg.configFile."kitty/kitty.conf" = {
      text = ''
        # Generated by Home Manager.
        # See https://sw.kovidgoyal.net/kitty/conf.html
      '' + concatStringsSep "\n" [
        (optionalString (cfg.font != null) ''
          font_family ${cfg.font.name}
          ${optionalString (cfg.font.size != null)
          "font_size ${toString cfg.font.size}"}
        '')

        (optionalString (cfg.themeFile != null) ''
          include ${pkgs.kitty-themes}/share/kitty-themes/themes/${cfg.themeFile}.conf
        '')
        ''
          # Shell integration is sourced and configured manually
          shell_integration ${cfg.shellIntegration.mode}
        ''
        (toKittyConfig cfg.settings)
        (toKittyKeybindings cfg.keybindings)
        (toKittyEnv cfg.environment)
        cfg.extraConfig
      ];
    } // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
      onChange = ''
        ${pkgs.procps}/bin/pkill -USR1 -u $USER kitty || true
      '';
    };

    home.activation.checkKittyTheme = mkIf (cfg.themeFile != null) (let
      themePath =
        "${pkgs.kitty-themes}/share/kitty-themes/themes/${cfg.themeFile}.conf";
    in hm.dag.entryBefore [ "writeBoundary" ] ''
      if [[ ! -f "${themePath}" ]]; then
        errorEcho "kitty-themes does not contain the theme file ${themePath}!"
        exit 1
      fi
    '');

    xdg.configFile."kitty/macos-launch-services-cmdline" = mkIf
      (cfg.darwinLaunchOptions != null && pkgs.stdenv.hostPlatform.isDarwin) {
        text = concatStringsSep " " cfg.darwinLaunchOptions;
      };

    programs.bash.initExtra =
      mkIf cfg.shellIntegration.enableBashIntegration shellIntegrationInit.bash;

    programs.fish.interactiveShellInit =
      mkIf cfg.shellIntegration.enableFishIntegration shellIntegrationInit.fish;

    programs.zsh.initExtra =
      mkIf cfg.shellIntegration.enableZshIntegration shellIntegrationInit.zsh;
  };
}
