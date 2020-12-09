{ config, lib, pkgs, ... }:

with lib;

let

  browserModule = defaultPkg: name: visible:
    let browser = (builtins.parseDrvName defaultPkg.name).name;
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
        defaultText = literalExample "pkgs.${browser}";
        description = "The ${name} package to use.";
      };

      extensions = mkOption {
        inherit visible;
        type = with types;
          let
            extensionType = submodule {
              options = {
                id = mkOption {
                  type = strMatching "[a-zA-Z]{32}";
                  description =
                    "The extension's ID from the Chome Web Store url or the unpacked crx.";
                  default = "";
                };
                updateUrl = mkOption {
                  type = str;
                  description =
                    "URL of the extension's update manifest XML file. (Linux only)";
                  default = "https://clients2.google.com/service/update2/crx";
                  visible = pkgs.stdenv.isLinux;
                  readOnly = pkgs.stdenv.isDarwin;
                };
                crxPath = mkOption {
                  type = either path bool;
                  description =
                    "Path to the extension's crx file. (Linux only)";
                  default = false;
                  visible = pkgs.stdenv.isLinux;
                };
                version = mkOption {
                  type = either str bool;
                  description =
                    "The extension's version, required for local installation. (Linux only)";
                  default = false;
                  visible = pkgs.stdenv.isLinux;
                };
              };
            };
          in listOf (coercedTo str (v: { id = v; }) extensionType);
        default = [ ];
        example = literalExample ''
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
          To install extensions outside of the Chrome Web Store set <literal>updateUrl</literal>
          or <literal>crxPath</literal> and <literal>version</literal> as explained in the
          <link xlink:href="https://developer.chrome.com/docs/extensions/mv2/external_extensions">Chrome documentation</link>.
        '';
      };
    };

  browserConfig = cfg:
    let

      browser = (builtins.parseDrvName cfg.package.name).name;

      darwinDirs = {
        chromium = "Chromium";
        google-chrome = "Google/Chrome";
        google-chrome-beta = "Google/Chrome Beta";
        google-chrome-dev = "Google/Chrome Dev";
      };

      configDir = if pkgs.stdenv.isDarwin then
        "Library/Application Support/${getAttr browser darwinDirs}"
      else
        "${config.xdg.configHome}/${browser}";

      extensionJson = ext:
        with builtins; {
          name = "${configDir}/External Extensions/${ext.id}.json";
          value.text = toJSON
            (if (isPath ext.crxPath && isString ext.version) then {
              external_crx = ext.crxPath;
              external_version = ext.version;
            } else {
              external_update_url = ext.updateUrl;
            });
        };

    in mkIf cfg.enable {
      home.packages = [ cfg.package ];
      home.file = listToAttrs (map extensionJson cfg.extensions);
    };

in {
  options.programs = {
    chromium = browserModule pkgs.chromium "Chromium" true;
    google-chrome = browserModule pkgs.google-chrome "Google Chrome" false;
    google-chrome-beta =
      browserModule pkgs.google-chrome-beta "Google Chrome Beta" false;
    google-chrome-dev =
      browserModule pkgs.google-chrome-dev "Google Chrome Dev" false;
  };

  config = mkMerge [
    (browserConfig config.programs.chromium)
    (browserConfig config.programs.google-chrome)
    (browserConfig config.programs.google-chrome-beta)
    (browserConfig config.programs.google-chrome-dev)
  ];
}
