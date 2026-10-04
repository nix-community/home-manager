{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.vicinae;
  vicinaeLib = import ./lib.nix { inherit pkgs; };

  jsonFormat = pkgs.formats.json { };
  tomlFormat = pkgs.formats.toml { };

  packageVersion = if cfg.package != null then lib.getVersion cfg.package else null;
  themeIsToml = packageVersion == null || lib.versionAtLeast packageVersion "0.15.0";
  versionPost0_17 = packageVersion == null || lib.versionAtLeast packageVersion "0.17.0";
  settingsPath =
    if cfg.enableMutableConfig then
      "vicinae/home-manager.json"
    else if versionPost0_17 then
      "vicinae/settings.json"
    else
      "vicinae/vicinae.json";
  settingsFile = config.home.file."${config.xdg.configHome}/${settingsPath}";
  mutableEnvironment =
    lib.optionalAttrs (cfg.enableMutableConfig && cfg.settings != { } && settingsFile.enable)
      {
        VICINAE_OVERRIDES =
          if lib.hasPrefix "/" settingsFile.target then
            settingsFile.target
          else
            "${config.home.homeDirectory}/${settingsFile.target}";
      };
in
{
  meta.maintainers = [ lib.maintainers.leiserfg ];

  options.programs.vicinae = {
    enable = lib.mkEnableOption "vicinae launcher daemon";

    package = lib.mkPackageOption pkgs "vicinae" { nullable = true; };

    enableMutableConfig = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        Whether to load declarative settings through {env}`VICINAE_OVERRIDES`,
        leaving {file}`vicinae/settings.json` writable by Vicinae. Declarative
        settings override changes to the same keys in the user file.
        Requires Vicinae 0.20.6 or later, which supports {env}`VICINAE_OVERRIDES`.
        When {option}`programs.vicinae.package` is null, the externally installed
        Vicinae is assumed to support this feature.
        Declarative settings are written to
        {file}`$XDG_CONFIG_HOME/vicinae/home-manager.json`. Use absolute or
        `~/` paths for declared imports; relative imports resolve against the
        generated file in the Nix store. Imported settings also override the
        user file.
        The installed declarative settings path must not contain a colon,
        because {env}`VICINAE_OVERRIDES` is a colon-separated list of paths.
        The user service receives {env}`VICINAE_OVERRIDES` directly. Otherwise,
        start Vicinae from a session that loads {option}`home.sessionVariables`.

        Before disabling this option while {option}`programs.vicinae.settings`
        is non-empty, remove or back up the Vicinae-owned
        {file}`$XDG_CONFIG_HOME/vicinae/settings.json`. Home Manager otherwise
        treats it as a file collision.
      '';
    };

    systemd = {
      enable = lib.mkEnableOption "vicinae systemd integration";

      autoStart = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "If the vicinae daemon should be started automatically";
      };

      target = lib.mkOption {
        type = lib.types.str;
        default = "graphical-session.target";
        example = "sway-session.target";
        description = ''
          The systemd target that will automatically start the vicinae service.
        '';
      };
    };

    useLayerShell = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Whether vicinae should use the layer shell.
        If you are using version 0.17 or newer, you should use
        {option}.programs.vicinae.settings.launcher_window.layer_shell.enabled = false
        instead.
      '';
    };
    enableFirefoxIntegration = lib.mkOption {
      default = true;
      description = ''
        Whether to install the messaging host so that the firefox extension <https://addons.mozilla.org/en-US/firefox/addon/vicinae/> works.
      '';
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        List of Vicinae extensions to install.

        You can use the `config.lib.vicinae.mkExtension` and `config.lib.vicinae.mkRayCastExtension` functions to create them, like:
        ```nix
         [
          (config.lib.vicinae.mkExtension {
            name = "test-extension";
            npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
            src =
              pkgs.fetchFromGitHub {
                owner = "schromp";
                repo = "vicinae-extensions";
                rev = "f8be5c89393a336f773d679d22faf82d59631991";
                sha256 = "sha256-zk7WIJ19ITzRFnqGSMtX35SgPGq0Z+M+f7hJRbyQugw=";
              }
              + "/test-extension";
          })
          (config.lib.vicinae.mkRayCastExtension {
            name = "gif-search";
            sha256 = "sha256-G7il8T1L+P/2mXWJsb68n4BCbVKcrrtK8GnBNxzt73Q=";
            rev = "4d417c2dfd86a5b2bea202d4a7b48d8eb3dbaeb1";
            npmDepsHash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
          })
          (config.lib.vicinae.mkRayCastExtension {
            name = "my-local-raycast-extension";
            src = ./extensions/my-local-raycast-extension;
          })
         ],
          ```

        Set `npmDepsHash` when `src` is produced by a fetcher such as
        `pkgs.fetchFromGitHub` or `pkgs.fetchgit`; otherwise
        dependency import reads `package-lock.json` from the fetched source
        during evaluation.
      '';
    };

    themes = lib.mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = ''
        Theme settings to add to the themes folder in `~/.config/vicinae/themes`. See <https://docs.vicinae.com/theming/getting-started> for supported values.

        The attribute name of the theme will be the name of theme file,
        e.g. `base16-default-dark` will be `base16-default-dark.toml` (or `.json` if vicinae version is < 0.15.0).
      '';
      example =
        lib.literalExpression # nix
          ''
            # vicinae >= 0.15.0
            {
              catppuccin-mocha = {
                meta = {
                  version = 1;
                  name = "Catppuccin Mocha";
                  description = "Cozy feeling with color-rich accents";
                  variant = "dark";
                  icon = "icons/catppuccin-mocha.png";
                  inherits = "vicinae-dark";
                };

                colors = {
                  core = {
                    background = "#1E1E2E";
                    foreground = "#CDD6F4";
                    secondary_background = "#181825";
                    border = "#313244";
                    accent = "#89B4FA";
                  };
                  accents = {
                    blue = "#89B4FA";
                    green = "#A6E3A1";
                    magenta = "#F5C2E7";
                    orange = "#FAB387";
                    purple = "#CBA6F7";
                    red = "#F38BA8";
                    yellow = "#F9E2AF";
                    cyan = "#94E2D5";
                  };
                };
              };
            }
          '';
    };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        favicon_service = "twenty";
        font.normal.size = 10;
        pop_to_root_on_close = false;
        search_files_in_root = false;
        theme = {
          dark.name = "vicinae-dark";
          light.name = "vicinae-light";
        };
      };
      description = ''
        Settings written as JSON to {file}`$XDG_CONFIG_HOME/vicinae/settings.json`
        ({file}`vicinae.json` before Vicinae 0.17), or to
        {file}`$XDG_CONFIG_HOME/vicinae/home-manager.json` when
        {option}`programs.vicinae.enableMutableConfig` is enabled.
        See {command}`vicinae config default`.
      '';
    };
  };

  config =
    let
      themeFiles = lib.mapAttrs' (
        name: theme:
        lib.nameValuePair "vicinae/themes/${name}.${if themeIsToml then "toml" else "json"}" {
          source = (if themeIsToml then tomlFormat else jsonFormat).generate "vicinae-${name}-theme" theme;
        }
      ) cfg.themes;
    in
    lib.mkIf cfg.enable {
      assertions = [
        (lib.hm.assertions.assertPlatform "programs.vicinae" pkgs lib.platforms.linux)
        {
          assertion =
            cfg.enableMutableConfig -> packageVersion == null || lib.versionAtLeast packageVersion "0.20.6";
          message = "programs.vicinae.enableMutableConfig requires Vicinae 0.20.6 or later.";
        }
        {
          assertion =
            !(mutableEnvironment ? VICINAE_OVERRIDES)
            || !(lib.hasInfix ":" mutableEnvironment.VICINAE_OVERRIDES);
          message = "programs.vicinae.enableMutableConfig cannot use a configuration path containing ':' because VICINAE_OVERRIDES is a colon-separated list.";
        }
        {
          assertion = cfg.systemd.enable -> cfg.package != null;
          message = "{option}programs.vicinae.systemd.enable requires non null {option}programs.vicinae.package";
        }
        {
          assertion = !cfg.useLayerShell -> !versionPost0_17;
          message = "After version 0.17, if you want to explicitly disable the use of layer shell, you need to set {option}.programs.vicinae.settings.launcher_window.layer_shell.enabled = false.";
        }
      ];

      lib.vicinae = vicinaeLib;

      home = {
        sessionVariables = lib.mapAttrs (
          _: value: lib.escape [ "\\" "\"" "$" "`" ] value
        ) mutableEnvironment;

        packages = lib.mkIf (cfg.package != null) [ cfg.package ];

        activation.vicinae-refresh-apps = lib.mkIf (cfg.package != null) (
          lib.hm.dag.entryAfter [ "installPackages" ] ''
            verboseEcho "Refreshing the vicinae app list"
            run --silence ${lib.getExe config.programs.vicinae.package} deeplink vicinae://launch/core/refresh-apps || verboseEcho "Failed to refresh the vicinae app list"
          ''
        );
      };

      xdg = {
        configFile = {
          "${settingsPath}" = lib.mkIf (cfg.settings != { }) {
            source = jsonFormat.generate "vicinae-settings" cfg.settings;
          };
        }
        // lib.optionalAttrs (!themeIsToml) themeFiles;

        dataFile =
          builtins.listToAttrs (
            map (item: {
              name = "vicinae/extensions/${item.name}";
              value.source = item;
            }) cfg.extensions
          )
          // lib.optionalAttrs themeIsToml themeFiles;
      };

      mozilla = lib.mkIf (cfg.enableFirefoxIntegration && cfg.package != null) (
        let
          vicinaeNativeMessagingHost =
            pkgs.writeTextDir "lib/mozilla/native-messaging-hosts/com.vicinae.vicinae.json"
              (
                builtins.toJSON {
                  name = "com.vicinae.vicinae";
                  description = "Vicinae Native Messaging Host";
                  path = "${cfg.package}/libexec/vicinae/vicinae-browser-link";
                  type = "stdio";
                  allowed_extensions = [ "firefox@vicinae.com" ];
                }
              );
        in
        {
          firefoxNativeMessagingHosts = [ vicinaeNativeMessagingHost ];
          librewolfNativeMessagingHosts = [ vicinaeNativeMessagingHost ];
        }
      );

      systemd.user.services.vicinae = lib.mkIf (cfg.systemd.enable && cfg.package != null) {
        Unit = {
          Description = "Vicinae server daemon";
          Documentation = [ "https://docs.vicinae.com" ];
          After = [ cfg.systemd.target ];
          PartOf = [ cfg.systemd.target ];
          X-Restart-Triggers =
            lib.optional (cfg.settings != { }) config.xdg.configFile.${settingsPath}.source
            ++ map (themeFile: themeFile.source) (lib.attrValues themeFiles)
            ++ cfg.extensions;
        };
        Service = {
          Environment = lib.mapAttrsToList (
            name: value: lib.replaceStrings [ "%" ] [ "%%" ] (builtins.toJSON "${name}=${value}")
          ) mutableEnvironment;
          Type = "simple";
          ExecStart = "${lib.getExe' cfg.package "vicinae"} server";
          Restart = "always";
          RestartSec = 5;
          KillMode = "process";
          EnvironmentFile = lib.mkIf (!versionPost0_17) (
            pkgs.writeText "vicinae-env" ''
              USE_LAYER_SHELL=${if cfg.useLayerShell then toString 1 else toString 0}
            ''
          );
        };
        Install = lib.mkIf cfg.systemd.autoStart {
          WantedBy = [ cfg.systemd.target ];
        };
      };
    };
}
