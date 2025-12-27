{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.programs.vicinae;

  jsonFormat = pkgs.formats.json { };
  tomlFormat = pkgs.formats.toml { };

  packageVersion = if cfg.package != null then lib.getVersion cfg.package else null;
  themeIsToml = lib.versionAtLeast packageVersion "0.15.0";
  versionPost0_17 = lib.versionAtLeast packageVersion "0.17.0";
in
{
  meta.maintainers = [ lib.maintainers.leiserfg ];

  options.programs.vicinae = {
    enable = lib.mkEnableOption "vicinae launcher daemon";

    package = lib.mkPackageOption pkgs "vicinae" { nullable = true; };

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
          })
         ],
          ```
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
      description = "Settings written as JSON to `~/.config/vicinae/settings.json.";
      example = lib.literalExpression ''
        {
          faviconService = "twenty";
          font = {
            size = 10;
          };
          popToRootOnClose = false;
          rootSearch = {
            searchFiles = false;
          };
          theme = {
            name = "vicinae-dark";
          };
          window = {
           csd = true;
           opacity = 0.95;
           rounding = 10;
          };
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.vicinae" pkgs lib.platforms.linux)
      {
        assertion = cfg.systemd.enable -> cfg.package != null;
        message = "{option}programs.vicinae.systemd.enable requires non null {option}programs.vicinae.package";
      }
      {
        assertion = !cfg.useLayerShell -> !versionPost0_17;
        message = ''After version 0.17, if you want to explicitly disable the use of layer shell, you need to set {option}.programs.vicinae.settings.launcher_window.layer_shell.enabled = false.'';
      }
    ];
    lib.vicinae.mkExtension = (
      {
        name,
        src,
      }:
      (pkgs.buildNpmPackage {
        inherit name src;
        installPhase = ''
          runHook preInstall

          mkdir -p $out
          cp -r /build/.local/share/vicinae/extensions/${name}/* $out/

          runHook postInstall
        '';
        npmDeps = pkgs.importNpmLock { npmRoot = src; };
        npmConfigHook = pkgs.importNpmLock.npmConfigHook;
      })
    );

    lib.vicinae.mkRayCastExtension = (
      {
        name,
        sha256,
        rev,
      }:
      let
        src =
          pkgs.fetchgit {
            inherit rev sha256;
            url = "https://github.com/raycast/extensions";
            sparseCheckout = [
              "/extensions/${name}"
            ];
          }
          + "/extensions/${name}";
      in
      (pkgs.buildNpmPackage {
        inherit name src;
        installPhase = ''
          runHook preInstall

          mkdir -p $out
          cp -r /build/.config/raycast/extensions/${name}/* $out/

          runHook postInstall
        '';
        npmDeps = pkgs.importNpmLock { npmRoot = src; };
        npmConfigHook = pkgs.importNpmLock.npmConfigHook;
      })
    );

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg =
      let
        themeFormat = if themeIsToml then tomlFormat else jsonFormat;
        themeExtension = if themeIsToml then "toml" else "json";
        themeFiles = lib.mapAttrs' (
          name: theme:
          lib.nameValuePair "vicinae/themes/${name}.${themeExtension}" {
            source = themeFormat.generate "vicinae-${name}-theme" theme;
          }
        ) cfg.themes;
        settingsPath = if versionPost0_17 then "vicinae/settings.json" else "vicinae/vicinae.json";
      in
      {
        configFile = {
          "${settingsPath}" = lib.mkIf (cfg.settings != { }) {
            source = jsonFormat.generate "vicinae-settings" cfg.settings;
          };
        }
        // lib.optionalAttrs (!themeIsToml) themeFiles;

        dataFile =
          builtins.listToAttrs (
            builtins.map (item: {
              name = "vicinae/extensions/${item.name}";
              value.source = item;
            }) cfg.extensions
          )
          // lib.optionalAttrs themeIsToml themeFiles;
      };

    systemd.user.services.vicinae = lib.mkIf (cfg.systemd.enable && cfg.package != null) {
      Unit = {
        Description = "Vicinae server daemon";
        Documentation = [ "https://docs.vicinae.com" ];
        After = [ cfg.systemd.target ];
        PartOf = [ cfg.systemd.target ];
      };
      Service = {
        Type = "simple";
        ExecStart = "${lib.getExe' cfg.package "vicinae"} server";
        Restart = "always";
        RestartSec = 5;
        KillMode = "process";
        EnvironmentFile = lib.mkIf (!versionPost0_17) (
          pkgs.writeText "vicinae-env" ''
            USE_LAYER_SHELL=${if cfg.useLayerShell then builtins.toString 1 else builtins.toString 0}
          ''
        );
      };
      Install = lib.mkIf cfg.systemd.autoStart {
        WantedBy = [ cfg.systemd.target ];
      };
    };
  };
}
