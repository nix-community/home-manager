{
  config,
  options,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    filter
    filterAttrs
    getExe
    hasSuffix
    head
    id
    length
    listToAttrs
    mkDefault
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    replaceStrings
    ;

  inherit (lib.types)
    listOf
    nullOr
    str
    submodule
    ;

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
      cp ${name} $out
    '';
  };

  publicExplorerSuffix = "$rid$path";
in
{
  options = {
    programs.radicle = {
      enable = mkEnableOption "Radicle";

      cli.package = mkPackageOption pkgs "radicle-node" { };

      uri = {
        rad = {
          browser = {
            enable = mkOption {
              description = "Whether to enable `rad:`-URI handling by web browser";
              default =
                (hasSuffix publicExplorerSuffix cfg.settings.publicExplorer) && pkgs.stdenv.hostPlatform.isLinux;
              defaultText = "`true` if a suitable public explorer is detected.";
              example = false;
            };
            preferredNode = mkOption {
              type = str;
              description = "The hostname of an instance of `radicle-node`, reachable via HTTPS.";
              default = "iris.radicle.xyz";
              example = "radicle-node.example.com";
            };
          };
          vscode = {
            enable = mkEnableOption "`rad:`-URI handling by VSCode";
            extension = mkOption {
              type = str;
              description = "The unique identifier of the VSCode extension that should handle `rad:`-URIs.";
              default = "radicle-ide-plugins-team.radicle";
            };
          };
        };
        web-rad =
          let
            detected =
              let
                detectionList = attrValues (
                  filterAttrs (n: _: config.programs.${n}.enable) {
                    librewolf = "librewolf.desktop";
                    firefox = "firefox.desktop";
                    chromium = "chromium-browser.desktop";
                  }
                );
              in
              lib.optionals (detectionList == [ ]) (head detectionList);
          in
          {
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
              default = detected;
              defaultText = "Automatically detected browser.";
              example = "brave.desktop";
            };
          };
      };

      settings = mkOption {
        default = { };
        description = "Radicle configuration, written to `~/.radicle/config.json.";

        type = submodule {
          freeformType = configFile.format.type;
          options = {
            publicExplorer = mkOption {
              type = str;
              description = "HTTPS URL pattern used to generate links to view content on Radicle via the browser.";
              default = "https://app.radicle.xyz/nodes/$host/$rid$path";
              example = "https://radicle.example.com/nodes/seed.example.com/$rid$path";
            };

            node = {
              alias = mkOption {
                type = str;
                description = "Human readable alias for your node.";
                default = config.home.username;
                defaultText = lib.literalExpression "config.home.username";
              };
              listen = mkOption {
                type = listOf str;
                description = "Addresses to bind to and listen for inbound connections.";
                default = [ ];
                example = [ "127.0.0.1:58776" ];
              };
            };
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion =
          !pkgs.stdenv.hostPlatform.isLinux
          -> (
            (filter id [
              cfg.uri.rad.browser.enable
              cfg.uri.rad.vscode.enable
            ]) == [ ]
          );
        message = "`rad:`-URI handlers are only supported on Linux.";
      }
      {
        assertion = cfg.uri.web-rad.enable -> cfg.uri.web-rad.browser != null;
        message = "Could not detect preferred browser. Please set `${builtins.toString opt.uri.web-rad.browser}`.";
      }
      {
        assertion =
          1 >= length (
            filter id [
              cfg.uri.rad.browser.enable
              cfg.uri.rad.vscode.enable
            ]
          );
        message = "At most one `rad:`-URI handler may be enabled.";
      }
      {
        assertion =
          cfg.uri.rad.browser.enable -> hasSuffix publicExplorerSuffix cfg.settings.publicExplorer;
        message = "${opt.uri.rad.browser.enable} is only compatible with a public explorer URL ending in '${publicExplorerSuffix}' but '${cfg.settings.publicExplorer}' does not end with '${publicExplorerSuffix}'.";
      }
    ];

    home = {
      packages = [ cfg.cli.package ];
      file.".radicle/${configFile.name}".source = configFile.path;
    };

    xdg = {
      mimeApps.defaultApplications = {
        "x-scheme-handler/rad" =
          let
            isEnabled = cfg.uri.rad.browser.enable || cfg.uri.rad.vscode.enable;

            handlerTarget =
              if cfg.uri.rad.browser.enable then
                "rad-to-browser.desktop"
              else if cfg.uri.rad.vscode.enable then
                "rad-to-vscode.desktop"
              else
                throw "unreachable";

            handler = mkDefault handlerTarget;
          in
          mkIf isEnabled handler;

        "x-scheme-handler/web+rad" = mkIf cfg.uri.web-rad.enable (mkDefault cfg.uri.web-rad.browser);
      };
      desktopEntries =
        let
          mkHandler =
            {
              name,
              shortName,
              prefix,
            }:
            {
              name = "Open Radicle URIs with ${name}";
              genericName = "Code Forge";
              categories = [
                "Development"
                "RevisionControl"
              ];
              exec = getExe (
                pkgs.writeShellApplication {
                  name = "rad-to-${shortName}";
                  meta.mainProgram = "rad-to-${shortName}";
                  text = ''xdg-open "${prefix}$1"'';
                }
              );
              mimeType = [ "x-scheme-handler/rad" ];
              noDisplay = true;
            };

          toHandler = v: {
            name = "rad-to-${v.shortName}";
            value = mkIf cfg.uri.rad.${v.shortName}.enable (mkHandler v);
          };
        in
        listToAttrs (
          map toHandler [
            {
              name = "Web Browser";
              shortName = "browser";
              prefix =
                replaceStrings
                  [ "$host" publicExplorerSuffix ]
                  [
                    cfg.uri.rad.browser.preferredNode
                    ""
                  ]
                  cfg.settings.publicExplorer;
            }
            {
              name = "VSCode";
              shortName = "vscode";
              prefix = "vscode://${cfg.uri.rad.vscode.extension}/";
            }
          ]
        );
    };
  };

  meta.maintainers = with lib.maintainers; [
    lorenzleutgeb
    matthiasbeyer
  ];
}
