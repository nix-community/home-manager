{ config, options, lib, pkgs, ... }:
let
  inherit (lib)
    attrValues filter filterAttrs getExe hasSuffix head id length listToAttrs
    mkDefault mkEnableOption mkIf mkOption mkPackageOption replaceStrings;

  inherit (lib.types)
    attrsOf bool enum ints listOf nullOr oneOf package path str submodule;

  cfg = config.programs.radicle;
  opt = options.programs.radicle;

  configFile = rec {
    format = pkgs.formats.json { };
    name = "config.json";
    path = pkgs.runCommand name { nativeBuildInputs = [ cfg.cli.package ]; } ''
      mkdir keys
      echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID/this/is/not/a/real/key/only/a/placeholder" \
        > keys/radicle.pub
      cp ${format.generate name cfg.settings} ${name}
      RAD_HOME=$PWD rad config
      echo lel
      exit 1
      cp ${name} $out
    '';
  };

  freeform = options:
    mkOption {
      default = { };
      type = submodule {
        inherit options;
        freeformType = configFile.format.type;
      };
    };

  publicExplorerSuffix = "$rid$path";
in {
  meta.maintainers = with lib.maintainers; [ lorenzleutgeb ];
  options = {
    programs.radicle = {
      enable = mkEnableOption "Radicle";
      cli = { package = mkPackageOption pkgs "radicle-cli" { }; };
      remote-helper = {
        package = mkPackageOption pkgs "radicle-remote-helper" { };
      };
      uri = {
        rad = {
          browser = {
            enable = mkOption {
              description =
                "Whether to enable `rad:`-URI handling by web browser";
              default =
                hasSuffix publicExplorerSuffix cfg.settings.publicExplorer;
              defaultText = "`true` if a suitable value for ${
                  toString opt.settings.publicExplorer
                } is detected.";
              example = false;
            };
            preferredNode = mkOption {
              type = str;
              default = "seed.radicle.garden";
            };
          };
          vscode = {
            enable = mkEnableOption "`rad:`-URI handling by VSCode";
            extension = mkOption {
              type = str;
              default = "radicle-ide-plugins-team.radicle";
            };
          };
        };
        web-rad = let
          detected = let
            detectionList = attrValues
              (filterAttrs (n: _: config.programs.${n}.enable) {
                librewolf = "librewolf.desktop";
                firefox = "firefox.desktop";
                chromium = "chromium-browser.desktop";
              });
          in if detectionList == [ ] then null else head detectionList;
        in {
          enable = mkEnableOption "`web+rad:`-URI handling by web browser";
          browser = mkOption {
            description = ''
              Name of the XDG Desktop Entry for your browser.
              LibreWolf, Firefox and Chromium configured via home-manager will
              be detected automatically. The value of this option should likely
              be the same as the output of
              `xdg-mime query default x-scheme-handler/https`.
            '';
            type = nullOr str;
            example = "brave.desktop";
            default = detected;
          };
        };
      };
      environment = mkOption {
        type = attrsOf (nullOr (oneOf [ str path package ]));
        default = {
          RUST_LOG = "info";
          RUST_BACKTRACE = "1";
        };
      };
      node = {
        args = mkOption {
          type = str;
          default = "--listen 0.0.0.0:8776 --force";
        };
        package = mkPackageOption pkgs "radicle-node" { };
      };
      httpd = {
        args = mkOption {
          type = str;
          default = "--listen 127.0.0.1:8080";
        };
        package = mkPackageOption pkgs "radicle-httpd" { };
      };
      settings = freeform {
        publicExplorer = mkOption {
          type = str;
          default = "https://app.radicle.xyz/nodes/$host/$rid$path";
        };
        preferredSeeds = mkOption {
          type = listOf str;
          default = [
            "z6MkrLMMsiPWUcNPHcRajuMi9mDfYckSoJyPwwnknocNYPm7@seed.radicle.garden:8776"
            "z6Mkmqogy2qEM2ummccUthFEaaHvyYmYBYh3dbe9W4ebScxo@ash.radicle.garden:8776"
          ];
        };
        web = freeform {
          pinned = freeform {
            repositories = mkOption {
              type = listOf str;
              default = [ ];
            };
          };
        };
        cli = freeform {
          hints = mkOption {
            type = bool;
            default = true;
          };
        };
        node = freeform {
          alias = mkOption {
            type = str;
            default = config.home.username;
          };
          network = mkOption {
            type = str;
            default = "main";
          };
          relay = mkOption {
            type = bool;
            default = true;
          };
          peers = freeform {
            type = mkOption {
              type = enum [ "static" "dynamic" ];
              default = "dynamic";
            };
            target = mkOption {
              type = ints.unsigned;
              default = 8;
            };
          };
          workers = mkOption {
            type = ints.unsigned;
            default = 8;
          };
          policy = mkOption {
            type = enum [ "allow" "block" ];
            default = "block";
          };
          scope = mkOption {
            type = enum [ "all" "followed" ];
            default = "all";
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.uri.web-rad.enable -> cfg.uri.web-rad.browser != null;
        message = "Could not detect preferred browser. Please set `${
            builtins.toString opt.uri.web-rad.browser
          }`.";
      }
      {
        assertion = 1 >= length
          (filter id [ cfg.uri.rad.browser.enable cfg.uri.rad.vscode.enable ]);
        message = "At most one `rad:`-URI handler may be enabled.";
      }
      {
        assertion = cfg.uri.rad.browser.enable
          -> hasSuffix publicExplorerSuffix cfg.settings.publicExplorer;
        message =
          "${opt.uri.rad.browser.enable} is only compatible with ${cfg.settings.publicExplorer} ending in '${publicExplorerSuffix}.";
      }
    ];

    home = {
      packages = [ cfg.cli.package cfg.remote-helper.package ];
      file.".radicle/${configFile.name}".source = configFile.path;
    };

    programs.git.enable = mkDefault true;

    services.ssh-agent.enable = mkDefault true;

    xdg = {
      mimeApps.defaultApplications = {
        "x-scheme-handler/rad" =
          mkIf (cfg.uri.rad.browser.enable || cfg.uri.rad.vscode.enable)
          (mkDefault ("rad-to-" + (if cfg.uri.rad.browser.enable then
            "browser"
          else if cfg.uri.rad.vscode.enable then
            "vscode"
          else
            throw "unreachable") + ".desktop"));
        "x-scheme-handler/web+rad" =
          mkIf cfg.uri.web-rad.enable (mkDefault cfg.uri.web-rad.browser);
      };
      desktopEntries = let
        handler = { name, shortName, prefix, }: {
          name = "Open Radicle URIs with ${name}";
          genericName = "Code Forge";
          categories = [ "Development" "RevisionControl" ];
          exec = getExe (pkgs.writeShellApplication {
            name = "rad-to-${shortName}";
            meta.mainProgram = "rad-to-${shortName}";
            text = ''xdg-open "${prefix}$1"'';
          });
          mimeType = [ "x-scheme-handler/rad" ];
          noDisplay = true;
        };
      in listToAttrs (map (v: {
        name = "rad-to-${v.shortName}";
        value = mkIf cfg.uri.rad.${v.shortName}.enable (handler v);
      }) [
        {
          name = "Web Browser";
          shortName = "browser";
          prefix = replaceStrings [ "$host" publicExplorerSuffix ] [
            cfg.uri.rad.browser.preferredNode
            ""
          ] cfg.settings.publicExplorer;
        }
        {
          name = "VSCode";
          shortName = "vscode";
          prefix = "vscode://${cfg.uri.rad.vscode.extension}/";
        }
      ]);
    };
  };
}
