{ config, lib, pkgs, ... }:

with lib;

let

  supportedBrowsers = [
    "chromium"
    "google-chrome"
    "google-chrome-beta"
    "google-chrome-dev"
    "brave"
    "vivaldi"
  ];

  browserModule = defaultPkg: name: visible:
    let
      browser = (builtins.parseDrvName defaultPkg.name).name;
      isProprietaryChrome = hasPrefix "Google Chrome" name;
    in {
      enable = mkOption {
        inherit visible;
        type = types.bool;
        default = false;
        example = true;
        description = "Whether to enable ${name}.";
      };

      package = mkOption {
        inherit visible;
        type = types.package;
        default = defaultPkg;
        defaultText = literalExpression "pkgs.${browser}";
        description = "The ${name} package to use.";
      };

      commandLineArgs = mkOption {
        inherit visible;
        type = types.listOf types.str;
        default = [ ];
        example = [ "--enable-logging=stderr" "--ignore-gpu-blocklist" ];
        description = ''
          List of command-line arguments to be passed to ${name}.

          For a list of common switches, see
          [Chrome switches](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/chrome/common/chrome_switches.cc).

          To search switches for other components, see
          [Chromium codesearch](https://source.chromium.org/search?q=file:switches.cc&ss=chromium%2Fchromium%2Fsrc).
        '';
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
                    The extension's ID from the Chrome Web Store url or the unpacked crx.
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
          [Chrome Web Store](https://chrome.google.com/webstore/category/extensions).

          To install extensions outside of the Chrome Web Store set
          `updateUrl` or `crxPath` and
          `version` as explained in the
          [Chrome
          documentation](https://developer.chrome.com/docs/extensions/mv2/external_extensions).
        '';
      };

      dictionaries = mkOption {
        inherit visible;
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression ''
          [
            pkgs.hunspellDictsChromium.en_US
          ]
        '';
        description = ''
          List of ${name} dictionaries to install.
        '';
      };
    };

  browserConfig = cfg:
    let

      drvName = (builtins.parseDrvName cfg.package.name).name;
      browser = if drvName == "ungoogled-chromium" then "chromium" else drvName;
      isProprietaryChrome = hasPrefix "google-chrome" drvName;

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

      dictionary = pkg: {
        name = "${configDir}/Dictionaries/${pkg.passthru.dictFileName}";
        value.source = pkg;
      };

      package = if cfg.commandLineArgs != [ ] then
        cfg.package.override {
          commandLineArgs = concatStringsSep " " cfg.commandLineArgs;
        }
      else
        cfg.package;

    in mkIf cfg.enable {
      home.packages = [ package ];
      home.file = optionalAttrs (!isProprietaryChrome) (listToAttrs
        ((map extensionJson cfg.extensions)
          ++ (map dictionary cfg.dictionaries)));
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
    vivaldi = browserModule pkgs.vivaldi "Vivaldi Browser" false;
  };

  config = mkMerge
    (map (browser: browserConfig config.programs.${browser}) supportedBrowsers);
}
