{ config, lib, pkgs, ... }:

with lib;

let

  browserModule = defaultPkg: name: visible:
    let
      browser = (builtins.parseDrvName defaultPkg.name).name;
      isProprietaryChrome = hasPrefix "Google Chrome" name;
    in {
      enable = mkOption {
        inherit visible;
        default = false;
        example = true;
        description = "Whether to enable ${name}.";
        type = lib.types.bool;
      };

      package = mkOption {
        inherit visible;
        type = types.package;
        default = defaultPkg;
        defaultText = literalExpression "pkgs.${browser}";
        description = "The ${name} package to use.";
      };
    } // optionalAttrs (!isProprietaryChrome) {
      # Extensions do not work with Google Chrome
      # see https://github.com/nix-community/home-manager/issues/1383
      extensions = mkOption {
        inherit visible;
        type = with types;
          let
            extensionType = submodule {
              options = {
                id = mkOption {
                  type = strMatching "[a-zA-Z]{32}";
                  description = ''
                    The extension's ID from the Chome Web Store url or the unpacked crx.
                  '';
                  default = "";
                };

                updateUrl = mkOption {
                  type = str;
                  description = ''
                    URL of the extension's update manifest XML file. Linux only.
                  '';
                  default = "https://clients2.google.com/service/update2/crx";
                  visible = pkgs.stdenv.isLinux;
                  readOnly = pkgs.stdenv.isDarwin;
                };

                crxPath = mkOption {
                  type = nullOr path;
                  description = ''
                    Path to the extension's crx file. Linux only.
                  '';
                  default = null;
                  visible = pkgs.stdenv.isLinux;
                };

                version = mkOption {
                  type = nullOr str;
                  description = ''
                    The extension's version, required for local installation. Linux only.
                  '';
                  default = null;
                  visible = pkgs.stdenv.isLinux;
                };
              };
            };
          in listOf (coercedTo str (v: { id = v; }) extensionType);
        default = [ ];
        example = literalExpression ''
          [
            { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
            {
              id = "dcpihecpambacapedldabdbpakmachpb";
              updateUrl = "https://raw.githubusercontent.com/iamadamdev/bypass-paywalls-chrome/master/updates.xml";
            }
            {
              id = "aaaaaaaaaabbbbbbbbbbcccccccccc";
              crxPath = "/home/share/extension.crx";
              version = "1.0";
            }
          ]
        '';
        description = ''
          List of ${name} extensions to install.
          To find the extension ID, check its URL on the
          <link xlink:href="https://chrome.google.com/webstore/category/extensions">Chrome Web Store</link>.
          </para><para>
          To install extensions outside of the Chrome Web Store set
          <literal>updateUrl</literal> or <literal>crxPath</literal> and
          <literal>version</literal> as explained in the
          <link xlink:href="https://developer.chrome.com/docs/extensions/mv2/external_extensions">Chrome
          documentation</link>.
        '';
      };
    };

  browserConfig = cfg:
    let

      drvName = (builtins.parseDrvName cfg.package.name).name;
      browser = if drvName == "ungoogled-chromium" then "chromium" else drvName;

      darwinDirs = {
        chromium = "Chromium";
        google-chrome = "Google/Chrome";
        google-chrome-beta = "Google/Chrome Beta";
        google-chrome-dev = "Google/Chrome Dev";
        brave = "BraveSoftware/Brave-Browser";
      };

      linuxDirs = { brave = "BraveSoftware/Brave-Browser"; };

      configDir = if pkgs.stdenv.isDarwin then
        "Library/Application Support/" + (darwinDirs."${browser}" or browser)
      else
        "${config.xdg.configHome}/" + (linuxDirs."${browser}" or browser);

      extensionJson = ext:
        assert ext.crxPath != null -> ext.version != null;
        with builtins; {
          name = "${configDir}/External Extensions/${ext.id}.json";
          value.text = toJSON (if ext.crxPath != null then {
            external_crx = ext.crxPath;
            external_version = ext.version;
          } else {
            external_update_url = ext.updateUrl;
          });
        };

    in mkIf cfg.enable {
      home.packages = [ cfg.package ];
      home.file = listToAttrs (map extensionJson (cfg.extensions or [ ]));
    };

in {
  # Extensions do not work with the proprietary Google Chrome version
  # see https://github.com/nix-community/home-manager/issues/1383
  imports = map (flip mkRemovedOptionModule
    "The `extensions` option does not work on Google Chrome anymore.") [
      [ "programs" "google-chrome" "extensions" ]
      [ "programs" "google-chrome-beta" "extensions" ]
      [ "programs" "google-chrome-dev" "extensions" ]
    ];

  options.programs = {
    chromium = browserModule pkgs.chromium "Chromium" true;
    google-chrome = browserModule pkgs.google-chrome "Google Chrome" false;
    google-chrome-beta =
      browserModule pkgs.google-chrome-beta "Google Chrome Beta" false;
    google-chrome-dev =
      browserModule pkgs.google-chrome-dev "Google Chrome Dev" false;
    brave = browserModule pkgs.brave "Brave Browser" false;
  };

  config = mkMerge [
    (browserConfig config.programs.chromium)
    (browserConfig config.programs.google-chrome)
    (browserConfig config.programs.google-chrome-beta)
    (browserConfig config.programs.google-chrome-dev)
    (browserConfig config.programs.brave)
  ];
}
