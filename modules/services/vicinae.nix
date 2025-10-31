{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.services.vicinae;
in
{
  meta.maintainers = [ lib.maintainers.leiserfg ];
  options.services.vicinae = {
    enable = lib.mkEnableOption "vicinae launcher daemon" // {
      default = false;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.vicinae;
      defaultText = lib.literalExpression "vicinae";
      description = "The vicinae package to use";
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "If the vicinae daemon should be started automatically";
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
      type = lib.types.attrsOf lib.types.attrs;
    };

    settings = lib.mkOption {
      type = lib.types.nullOr lib.types.attrs;
      default = null;
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

    home.packages = [ cfg.package ];

    xdg.configFile =
      lib.optionalAttrs (cfg.settings != null) {
        "vicinae/vicinae.json".text = builtins.toJSON cfg.settings;
      }
      // lib.mapAttrs' (
        name: theme:
        lib.nameValuePair "vicinae/themes/${name}.json" {
          text = builtins.toJSON theme;
        }
      ) cfg.themes;

    xdg.dataFile = builtins.listToAttrs (
      builtins.map (item: {
        name = "vicinae/extensions/${item.name}";
        value.source = item;
      }) config.services.vicinae.extensions
    );

    systemd.user.services.vicinae = {
      Unit = {
        Description = "Vicinae server daemon";
        Documentation = [ "https://docs.vicinae.com" ];
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
        BindsTo = [ "graphical-session.target" ];
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
      Install = lib.mkIf cfg.autoStart {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
