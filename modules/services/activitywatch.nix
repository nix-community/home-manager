{ config, options, lib, pkgs, ... }:

let
  inherit (lib) mkOption;

  cfg = config.services.activitywatch;

  mkWatcherService = name: cfg:
    let jobName = "activitywatch-watcher-${cfg.name}";
    in lib.nameValuePair jobName {
      Unit = {
        Description = "ActivityWatch watcher '${cfg.name}'";
        After = [ "activitywatch.service" ];
        BindsTo = [ "activitywatch.target" ];
      };

      Service = {
        ExecStart = "${lib.getExe' cfg.package cfg.executable} ${
            lib.escapeShellArgs cfg.extraOptions
          }";

        # Some sandboxing.
        LockPersonality = true;
        NoNewPrivileges = true;
        RestrictNamespaces = true;
      };

      Install.WantedBy = [ "activitywatch.target" ];
    };

  # Most ActivityWatch client libraries has a function that loads with a
  # certain configuration format for all watchers and itself which is nice for
  # us but watchers can load configuration in any location. We just hope
  # they're following it.
  watcherSettingsFormat = pkgs.formats.toml { };

  # The module interface for the watchers.
  watcherType = { name, config, options, ... }: {
    options = {
      name = mkOption {
        type = lib.types.str;
        default = name;
        example = "aw-watcher-afk";
        description = ''
          The name of the watcher. This will be used as the directory name for
          {file}`$XDG_CONFIG_HOME/activitywatch/$NAME` when
          {option}`services.activitywatch.watchers.<name>.settings` is set.
        '';
      };

      package = mkOption {
        type = lib.types.package;
        example = lib.literalExpression "pkgs.activitywatch";
        description = ''
          The derivation containing the watcher executable.
        '';
      };

      executable = mkOption {
        type = lib.types.str;
        default = config.name;
        description = ''
          The name of the executable of the watcher. This is useful in case the
          watcher name is different from the executable. By default, this
          option uses the watcher name.
        '';
      };

      settings = mkOption {
        type = watcherSettingsFormat.type;
        default = { };
        example = {
          timeout = 300;
          poll_time = 2;
        };
        description = ''
          The settings for the individual watcher in TOML format. If set, a
          file will be generated at
          {file}`$XDG_CONFIG_HOME/activitywatch/$NAME/$FILENAME`.

          To set the basename of the settings file, see
          [](#opt-services.activitywatch.watchers._name_.settingsFilename).
        '';
      };

      settingsFilename = mkOption {
        type = lib.types.str;
        default = "${config.name}.toml";
        example = "config.toml";
        description = ''
          The filename of the generated settings file. By default, this uses
          the watcher name to be generated at
          {file}`$XDG_CONFIG_HOME/activitywatch/$NAME/$NAME.toml`.

          This is useful in case the watcher requires a different name for the
          configuration file.
        '';
      };

      extraOptions = mkOption {
        type = with lib.types; listOf str;
        default = [ ];
        example = [ "--host" "127.0.0.1" ];
        description = ''
          Extra arguments to be passed to the watcher executable.
        '';
      };
    };
  };

  generateWatchersConfig = name: cfg:
    let
      # We're only assuming the generated filepath this since most watchers
      # uses the ActivityWatch client library which has `load_config_toml`
      # utility function for easily loading the configuration files.
      filename = "activitywatch/${cfg.name}/${cfg.settingsFilename}";
    in lib.nameValuePair filename (lib.mkIf (cfg.settings != { }) {
      source = watcherSettingsFormat.generate
        "activitywatch-watcher-${cfg.name}-settings" cfg.settings;
    });
in {
  meta.maintainers = with lib.maintainers; [ foo-dogsquared ];

  options.services.activitywatch = {
    enable = lib.mkEnableOption "ActivityWatch, an automated time tracker";

    package = mkOption {
      description = ''
        Package containing [the Rust implementation of ActivityWatch
        server](https://github.com/ActivityWatch/aw-server-rust).
      '';
      type = lib.types.package;
      default = pkgs.activitywatch;
      defaultText = lib.literalExpression "pkgs.activitywatch";
      example = lib.literalExpression "pkgs.aw-server-rust";
    };

    settings = mkOption {
      description = ''
        Configuration for `aw-server-rust` to be generated at
        {file}`$XDG_CONFIG_HOME/activitywatch/aw-server-rust/config.toml`.
      '';
      type = watcherSettingsFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          port = 3012;

          custom_static = {
            my-custom-watcher = "''${pkgs.my-custom-watcher}/share/my-custom-watcher/static";
            aw-keywatcher = "''${pkgs.aw-keywatcher}/share/aw-keywatcher/static";
          };
        }
      '';
    };

    extraOptions = mkOption {
      description = ''
        Additional arguments to be passed on to the ActivityWatch server.
      '';
      type = with lib.types; listOf str;
      default = [ ];
      example = [ "--port" "5999" ];
    };

    watchers = mkOption {
      description = ''
        Watchers to be included with the service alongside with their
        configuration.

        If a configuration is set, a file will be generated in
        {file}`$XDG_CONFIG_HOME/activitywatch/$WATCHER_NAME/$WATCHER_SETTINGS_FILENAME`.

        ::: {.note}
        The watchers are run with the service manager and the settings format
        of the configuration is only assumed to be in TOML. Furthermore, it
        assumes the watcher program is using the official client libraries
        which has functions to store it in the appropriate location.
        :::
      '';
      type = with lib.types; attrsOf (submodule watcherType);
      default = { };
      example = lib.literalExpression ''
        {
          aw-watcher-afk = {
            package = pkgs.activitywatch;
            settings = {
              timeout = 300;
              poll_time = 2;
            };
          };

          aw-watcher-windows = {
            package = pkgs.activitywatch;
            settings = {
              poll_time = 1;
              exclude_title = true;
            };
          };

          my-custom-watcher = {
            package = pkgs.my-custom-watcher;
            executable = "mcw";
            settings = {
              hello = "there";
              enable_greetings = true;
              poll_time = 5;
            };
            settingsFilename = "config.toml";
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.activitywatch" pkgs
        lib.platforms.linux)
    ];

    # We'll group these services with a target to make it easier to manage for
    # the maintainers and the user. Win-win.
    systemd.user.targets.activitywatch = {
      Unit = {
        Description = "ActivityWatch server";
        Requires = [ "default.target" ];
        After = [ "default.target" ];
      };

      Install.WantedBy = [ "default.target" ];
    };

    systemd.user.services = lib.mapAttrs' mkWatcherService cfg.watchers // {
      activitywatch = {
        Unit = {
          Description = "ActivityWatch time tracker server";
          Documentation = [ "https://docs.activitywatch.net" ];
          BindsTo = [ "activitywatch.target" ];
        };

        Service = {
          ExecStart = "${lib.getExe' cfg.package "aw-server"} ${
              lib.escapeShellArgs cfg.extraOptions
            }";
          Restart = "on-failure";

          # Some sandboxing.
          LockPersonality = true;
          NoNewPrivileges = true;
          RestrictNamespaces = true;
        };

        Install.WantedBy = [ "activitywatch.target" ];
      };
    };

    xdg.configFile = lib.mapAttrs' generateWatchersConfig cfg.watchers
      // lib.optionalAttrs (cfg.settings != { }) {
        "activitywatch/aw-server-rust/config.toml" = {
          source = watcherSettingsFormat.generate
            "activitywatch-server-rust-config.toml" cfg.settings;
        };
      };
  };
}
