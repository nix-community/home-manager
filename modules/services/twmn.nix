{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  cfg = config.services.twmn;
  iniFormat = pkgs.formats.ini {
    mkKeyValue = lib.generators.mkKeyValueDefault { } "=";
  };

  renamedOptions = [
    {
      old = "duration";
      new = "main.duration";
    }
    {
      old = "host";
      new = "main.host";
    }
    {
      old = "port";
      new = "main.port";
    }
    {
      old = "soundCommand";
      new = "main.sound_command";
    }
    {
      old = "text.color";
      new = "gui.foreground_color";
    }
    {
      old = "text.font.family";
      new = "gui.font";
    }
    {
      old = "text.font.size";
      new = "gui.font_size";
    }
    {
      old = "text.font.variant";
      new = "gui.font_variant";
    }
    {
      old = "window.alwaysOnTop";
      new = "gui.always_on_top";
    }
    {
      old = "window.animation.bounce.enable";
      new = "gui.bounce";
    }
    {
      old = "window.animation.bounce.duration";
      new = "gui.bounce_duration";
    }
    {
      old = "window.color";
      new = "gui.background_color";
    }
    {
      old = "window.height";
      new = "gui.height";
    }
    {
      old = "window.opacity";
      new = "gui.opacity";
    }
    {
      old = "window.position";
      new = "gui.position";
    }
  ];

  legacyOption = path: lib.getAttrFromPath (lib.splitString "." path) options.services.twmn;

  hasLegacyOptions =
    let
      convertedOptions = [
        "screen"
        "icons.critical"
        "icons.info"
        "icons.warning"
        "text.maxLength"
        "window.offset.x"
        "window.offset.y"
        "window.animation.easeIn"
        "window.animation.easeOut"
      ];
    in
    lib.any (rename: (legacyOption rename.old).isDefined) renamedOptions
    || lib.any (path: (legacyOption path).highestPrio < 1500) convertedOptions
    || cfg.extraConfig != { };

  convertOption =
    old: new: convert:
    lib.mkChangedOptionModule (lib.splitString "." "services.twmn.${old}") [
      "services"
      "twmn"
      "settings"
    ] (_: lib.setAttrByPath (lib.splitString "." new) (lib.mkDerivedConfig (legacyOption old) convert));

  offsetToString = value: if value < 0 then toString value else "+${toString value}";

  convertAnimation =
    name:
    lib.mkChangedOptionModule
      [ "services" "twmn" "window" "animation" name ]
      [ "services" "twmn" "settings" ]
      (_: {
        gui = cfg.window.animation.${name}._settings;
      });

in
{
  meta.maintainers = [ lib.hm.maintainers.austreelis ];

  imports =
    lib.hm.deprecations.mkSettingsRenamedOptionModules
      [ "services" "twmn" ]
      [ "services" "twmn" "settings" ]
      { }
      (map (lib.mapAttrs (_: lib.splitString ".")) renamedOptions)
    ++ [
      (convertOption "screen" "gui.screen" toString)
      (convertOption "icons.critical" "icons.critical" toString)
      (convertOption "icons.info" "icons.info" toString)
      (convertOption "icons.warning" "icons.warning" toString)
      (convertOption "text.maxLength" "gui.max_length" (value: if value == null then -1 else value))
      (convertOption "window.offset.x" "gui.offset_x" offsetToString)
      (convertOption "window.offset.y" "gui.offset_y" offsetToString)
      (convertAnimation "easeIn")
      (convertAnimation "easeOut")
    ];

  options.services.twmn = {
    enable = lib.mkEnableOption "twmn, a tiling window manager notification daemon";

    settings = lib.mkOption {
      inherit (iniFormat) type;
      default = { };
      # extraConfig historically overrides even forced modeled values.
      apply =
        settings:
        lib.recursiveUpdate settings (
          lib.mapAttrs (_: lib.mapAttrs (_: value: "${value}")) cfg.extraConfig
        );
      example = {
        gui = {
          font_size = 16;
          background_color = "#000000";
          offset_x = "+20";
        };
        main.duration = 5000;
      };
      description = ''
        Configuration for twmnd in INI format. See
        <https://github.com/sboli/twmn/blob/master/README.md>
        for available settings. Generated files include `main.port = 9797`
        unless configured explicitly, because TWMN requires it in a managed file.

        No configuration file is generated when settings are empty. Deprecated
        options retain the historical defaults that disable always-on-top and
        bouncing and set the outgoing animation curve to 38. Forcing the whole
        settings value suppresses these legacy GUI defaults; forcing a section
        does not suppress omitted defaults. Settings-only configurations use
        TWMN's defaults for omitted keys. Use signed strings
        such as `"+20"` for offsets, `-1` for unlimited `gui.max_length`, and
        an empty string for an unset screen or icon.

        The deprecated `extraConfig` option remains a final override, including
        over forced settings. Move its values into settings and resolve any
        duplicate definitions when migrating.

        Aliases expose final settings values, not omitted native defaults.
        Reading legacy aliases to derive other settings can cause infinite
        recursion. Use shared local bindings for related values instead.
      '';
    };

    text.font.package = lib.mkPackageOption pkgs "font" {
      default = null;
      example = "pkgs.dejavu_fonts";
      nullable = true;
      extraDescription = "Package providing the notification font.";
    };

    extraConfig = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      visible = false;
      description = "Deprecated final override for services.twmn.settings.";
    };

    window.animation =
      let
        animationType =
          name: direction:
          let
            outerOption = options.services.twmn.window.animation.${name};
          in
          lib.types.submodule (
            { options, ... }:
            let
              # Keep defaults weak and preserve explicit leaf priorities. A forced
              # animation must not replace unrelated GUI settings.
              project =
                leaf:
                lib.mkOverride (
                  if leaf.highestPrio == lib.modules.defaultOverridePriority then
                    outerOption.highestPrio
                  else
                    leaf.highestPrio
                ) leaf.value;
            in
            {
              options = {
                curve = lib.mkOption {
                  type = lib.types.ints.between 0 40;
                  default = 38;
                };
                duration = lib.mkOption {
                  type = lib.types.ints.unsigned;
                  default = 1000;
                };
                # Functions can still read numeric curve and duration values.
                _settings = lib.mkOption {
                  type = lib.types.raw;
                  internal = true;
                  visible = false;
                  readOnly = true;
                  default = {
                    "${direction}_animation" = project options.curve;
                    "${direction}_animation_duration" = project options.duration;
                  };
                };
              };
            }
          );

      in
      {
        easeIn = lib.mkOption { type = lib.types.either lib.types.str (animationType "easeIn" "in"); };
        easeOut = lib.mkOption { type = lib.types.either lib.types.str (animationType "easeOut" "out"); };
      };
  };

  config = lib.mkMerge [
    {
      warnings = lib.optional (cfg.extraConfig != { }) ''
        The option `services.twmn.extraConfig' is deprecated. Move its values to
        `services.twmn.settings' and resolve duplicate definitions there.
      '';
    }
    (lib.mkIf cfg.enable {
      assertions = [
        (lib.hm.assertions.assertPlatform "services.twmn" pkgs lib.platforms.linux)
      ];

      home.packages = lib.optional (cfg.text.font.package != null) cfg.text.font.package ++ [ pkgs.twmn ];

      xdg.configFile."twmn/twmn.conf" = lib.mkIf (cfg.settings != { }) {
        source =
          let
            # Whole-settings overrides also discard historical defaults.
            preserveLegacyDefaults =
              hasLegacyOptions
              && options.services.twmn.settings.highestPrio >= lib.modules.defaultOverridePriority;
            defaults = {
              # TWMN tries to replace a managed configuration if main.port is absent.
              main.port = 9797;
            }
            // lib.optionalAttrs preserveLegacyDefaults {
              gui = {
                always_on_top = false;
                bounce = false;
                out_animation = 38;
              };
            };
          in
          iniFormat.generate "twmn.conf" (lib.recursiveUpdate defaults cfg.settings);
      };

      systemd.user.services.twmnd = {
        Unit = {
          Description = "twmn daemon";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
          X-Restart-Triggers = lib.optional (
            cfg.settings != { }
          ) "${config.xdg.configFile."twmn/twmn.conf".source}";
        };

        Install.WantedBy = [ "graphical-session.target" ];

        Service = {
          ExecStart = "${pkgs.twmn}/bin/twmnd";
          Restart = "on-failure";
          Type = "simple";
          StandardOutput = "null";
        };
      };
    })
  ];
}
