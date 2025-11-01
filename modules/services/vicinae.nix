{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.vicinae;

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.maintainers.leiserfg ];

  options.services.vicinae = {
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
      description = "If vicinae should use the layer shell";
    };

    extensions = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        List of Vicinae extensions to install.

        You can use the `config.lib.vicinae.mkExtension` function to create them, like:
        ```nix
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
          ```
      '';
    };

    themes = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        Theme settings to add to the themes folder in `~/.config/vicinae/themes`.

        The attribute name of the theme will be the name of theme json file,
        e.g. `base16-default-dark` will be `base16-default-dark.json`.
      '';
      example =
        lib.literalExpression # nix
          ''
            {
              base16-default-dark = {
                version = "1.0.0";
                appearance = "dark";
                icon = /path/to/icon.png;
                name = "base16 default dark";
                description = "base16 default dark by Chris Kempson";
                palette = {
                  background = "#181818";
                  foreground = "#d8d8d8";
                  blue = "#7cafc2";
                  green = "#a3be8c";
                  magenta = "#ba8baf";
                  orange = "#dc9656";
                  purple = "#a16946";
                  red = "#ab4642";
                  yellow = "#f7ca88";
                  cyan = "#86c1b9";
                };
              };
            }
          '';
    };

    settings = lib.mkOption {
      inherit (jsonFormat) type;
      default = { };
      description = "Settings written as JSON to `~/.config/vicinae/vicinae.json.";
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
      {
        assertion = cfg.systemd.enable -> cfg.package != null;
        message = "{option}services.vicinae.systemd.enable requires non null {option}services.vicinae.package";
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

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg = {
      configFile = {
        "vicinae/vicinae.json" = lib.mkIf (cfg.settings != { }) {
          source = jsonFormat.generate "vicinae-settings" cfg.settings;
        };
      }
      // lib.mapAttrs' (
        name: theme:
        lib.nameValuePair "vicinae/themes/${name}.json" {
          text = builtins.toJSON theme;
        }
      ) cfg.themes;

      dataFile = builtins.listToAttrs (
        builtins.map (item: {
          name = "vicinae/extensions/${item.name}";
          value.source = item;
        }) cfg.extensions
      );
    };

    systemd.user.services.vicinae = lib.mkIf (cfg.systemd.enable && cfg.package != null) {
      Unit = {
        Description = "Vicinae server daemon";
        Documentation = [ "https://docs.vicinae.com" ];
        After = [ cfg.systemd.target ];
        PartOf = [ cfg.systemd.target ];
        BindsTo = [ cfg.systemd.target ];
      };
      Service = {
        EnvironmentFile = pkgs.writeText "vicinae-env" ''
          USE_LAYER_SHELL=${if cfg.useLayerShell then builtins.toString 1 else builtins.toString 0}
        '';
        Type = "simple";
        ExecStart = "${lib.getExe' cfg.package "vicinae"} server";
        Restart = "always";
        RestartSec = 5;
        KillMode = "process";
      };
      Install = lib.mkIf cfg.systemd.autoStart {
        WantedBy = [ cfg.systemd.target ];
      };
    };
  };
}
