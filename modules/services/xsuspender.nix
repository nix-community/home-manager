{
  config,
  lib,
  options,
  pkgs,
  ...
}:

let
  inherit (lib) mkOption types;

  cfg = config.services.xsuspender;

  iniFormat = pkgs.formats.ini { };

  renamedSettings = [
    "matchWmClassContains"
    "matchWmClassGroupContains"
    "matchWmNameContains"
    "suspendDelay"
    "resumeEvery"
    "resumeFor"
    "execSuspend"
    "execResume"
    "sendSignals"
    "suspendSubtreePattern"
    "onlyOnBattery"
    "autoSuspendOnBattery"
    "downclockOnBattery"
  ];

in
{
  imports = [
    (lib.doRename {
      from = [
        "services"
        "xsuspender"
        "defaults"
      ];
      to = [
        "services"
        "xsuspender"
        "settings"
        "Default"
      ];
      visible = false;
      warn = true;
      use = lib.id;
      # Do not create a Default section when the old option is unused.
      condition = options.services.xsuspender.defaults.isDefined;
    })
  ]
  ++
    lib.hm.deprecations.mkSettingsRenamedOptionModules
      [ "services" "xsuspender" ]
      [ "services" "xsuspender" ]
      { }
      [
        {
          old = "rules";
          new = "settings";
        }
      ];

  meta.maintainers = [ ];

  options = {
    services.xsuspender = {
      enable = lib.mkEnableOption "XSuspender";

      package = lib.mkPackageOption pkgs "xsuspender" { };

      settings = mkOption {
        type = types.attrsOf (
          types.submodule {
            # Legacy rule functions can read sibling options through their aliases.
            freeformType = types.lazyAttrsOf iniFormat.lib.types.atom;
            imports = lib.hm.deprecations.mkSettingsRenamedOptionModules [ ] [ ] { } renamedSettings;
          }
        );
        default = { };
        example = {
          Default = {
            suspend_delay = 10;
            resume_every = 60;
          };
          Chromium = {
            match_wm_class_contains = "chromium-browser";
          };
        };
        description = ''
          Configuration settings for XSuspender. No configuration file is
          managed when this is empty. The old `defaults` and `rules` options
          are aliases that retain their historical defaults at option-default
          priority. Ordinary settings assignments override those defaults.
          Sections configured only through settings use native defaults for
          omitted or null keys.

          See <https://kernc.github.io/xsuspender/> for available settings.
        '';
      };

      debug = mkOption {
        description = "Whether to enable debug output.";
        type = types.bool;
        default = false;
      };

    };
  };

  config = lib.mkMerge [
    {
      services.xsuspender.settings =
        let
          inherit (lib.modules) mapDefinitionValue mkAliasAndWrapDefsWithPriority;

          legacyDefaults = lib.mapAttrs (_: lib.mkOptionDefault) {
            suspend_delay = 5;
            resume_every = 50;
            resume_for = 5;
            send_signals = true;
            only_on_battery = false;
            auto_suspend_on_battery = true;
            downclock_on_battery = 0;
          };

          # Preserve conditions and priorities without evaluating recursive alias values.
          sectionDefaults = mapDefinitionValue (_: legacyDefaults);

          defaultsFromRules =
            definitions:
            let
              # Seed Default independently: a disabled rule named Default must not erase it.
              defaultSection = mapDefinitionValue (_: { Default = legacyDefaults; }) definitions;
              ruleSections = mapDefinitionValue (lib.mapAttrs (_: sectionDefaults)) definitions;
            in
            lib.mkMerge [
              defaultSection
              ruleSections
            ];
        in
        lib.mkMerge [
          (mkAliasAndWrapDefsWithPriority (definitions: {
            Default = sectionDefaults definitions;
          }) options.services.xsuspender.defaults)
          (mkAliasAndWrapDefsWithPriority defaultsFromRules options.services.xsuspender.rules)
        ];
    }
    (lib.mkIf cfg.enable {
      assertions = [
        (lib.hm.assertions.assertPlatform "services.xsuspender" pkgs lib.platforms.linux)
      ];

      # To make the xsuspender tool available.
      home.packages = [ cfg.package ];

      xdg.configFile."xsuspender.conf" = lib.mkIf (cfg.settings != { }) {
        # Keep aliases readable in config; omit them and unset values only in the INI.
        source = iniFormat.generate "xsuspender.conf" (
          lib.mapAttrs (
            _: section: lib.filterAttrs (_: value: value != null) (removeAttrs section renamedSettings)
          ) cfg.settings
        );
      };

      systemd.user.services.xsuspender = {
        Unit = {
          Description = "XSuspender";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
          X-Restart-Triggers = lib.optional (
            cfg.settings != { }
          ) "${config.xdg.configFile."xsuspender.conf".source}";
        };

        Service = {
          ExecStart = lib.getExe cfg.package;
          Environment = lib.mkIf cfg.debug [ "G_MESSAGES_DEBUG=all" ];
        };

        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    })
  ];
}
