{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkOption types;

  supportedBrowsers = {
    chromium = "Chromium";
    google-chrome = "Google Chrome";
    google-chrome-beta = "Google Chrome Beta";
    google-chrome-dev = "Google Chrome Dev";
    brave = "Brave Browser";
    vivaldi = "Vivaldi Browser";
  };

  browserModule =
    browser: name: visible:
    let
      isProprietaryChrome = lib.hasPrefix "Google Chrome" name;
    in
    {
      enable = mkOption {
        inherit visible;
        type = types.bool;
        default = false;
        example = true;
        description = "Whether to enable ${name}.";
      };

      package = mkOption {
        inherit visible;
        type = types.nullOr types.package;
        default = pkgs.${browser};
        defaultText = literalExpression "pkgs.${browser}";
        description = "The ${name} package to use.";
      };

      finalPackage = mkOption {
        inherit visible;
        type = types.nullOr types.package;
        readOnly = true;
        description = ''
          Resulting customized ${name} package
        '';
      };

      commandLineArgs = mkOption {
        inherit visible;
        type = types.listOf types.str;
        default = [ ];
        example = [
          "--enable-logging=stderr"
          "--ignore-gpu-blocklist"
        ];
        description = ''
          List of command-line arguments to be passed to ${name}.

          For a list of common switches, see
          [Chrome switches](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/chrome/common/chrome_switches.cc).

          To search switches for other components, see
          [Chromium codesearch](https://source.chromium.org/search?q=file:switches.cc&ss=chromium%2Fchromium%2Fsrc).
        '';
      };
    }
    // lib.optionalAttrs (!isProprietaryChrome) {
      # Extensions do not work with Google Chrome
      # see https://github.com/nix-community/home-manager/issues/1383
      extensions = mkOption {
        inherit visible;
        type =
          with types;
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
                  default = "https://clients2.google.com/service/update2/crx";
                  description = ''
                    URL of the extension's update manifest XML file. Linux only.
                  '';
                };

                crxPath = mkOption {
                  type = nullOr path;
                  default = null;
                  description = ''
                    Path to the extension's crx file. Linux only.
                  '';
                };

                version = mkOption {
                  type = nullOr str;
                  default = null;
                  description = ''
                    The extension's version, required for local installation. Linux only.
                  '';
                };
              };
            };
          in
          listOf (coercedTo str (v: { id = v; }) extensionType);
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
      nativeMessagingHosts = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression ''
          [
            pkgs.kdePackages.plasma-browser-integration
          ]
        '';
        description = ''
          List of ${name} native messaging hosts to install.
        '';
      };
    };

  browserConfig =
    browser: cfg:
    let

      isProprietaryChrome = lib.hasPrefix "google-chrome" browser;

      darwinDirs = {
        chromium = "Chromium";
        google-chrome = "Google/Chrome";
        google-chrome-beta = "Google/Chrome Beta";
        google-chrome-dev = "Google/Chrome Dev";
        brave = "BraveSoftware/Brave-Browser";
      };

      linuxDirs = {
        brave = "BraveSoftware/Brave-Browser";
      };

      configDir =
        if pkgs.stdenv.isDarwin then
          "Library/Application Support/" + (darwinDirs."${browser}" or browser)
        else
          "${config.xdg.configHome}/" + (linuxDirs."${browser}" or browser);

      extensionJson =
        ext:
        assert ext.crxPath != null -> ext.version != null;
        with builtins;
        {
          name = "${configDir}/External Extensions/${ext.id}.json";
          value.text = toJSON (
            if ext.crxPath != null then
              {
                external_crx = ext.crxPath;
                external_version = ext.version;
              }
            else
              {
                external_update_url = ext.updateUrl;
              }
          );
        };

      dictionary = pkg: {
        name = "${configDir}/Dictionaries/${pkg.passthru.dictFileName}";
        value.source = pkg;
      };

      nativeMessagingHostsJoined = pkgs.symlinkJoin {
        name = "${browser}-native-messaging-hosts";
        paths = cfg.nativeMessagingHosts;
      };

    in

    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !(cfg.package == null && cfg.commandLineArgs != [ ]);
          message = "Cannot set `commandLineArgs` when `package` is null for ${browser}.";
        }
      ];

      programs.${browser}.finalPackage =
        if cfg.commandLineArgs != [ ] then
          cfg.package.override {
            commandLineArgs = lib.concatStringsSep " " cfg.commandLineArgs;
          }
        else
          cfg.package;

      home.packages = lib.mkIf (cfg.finalPackage != null) [
        cfg.finalPackage
      ];
      home.file = lib.optionalAttrs (!isProprietaryChrome) (
        lib.listToAttrs ((map extensionJson cfg.extensions) ++ (map dictionary cfg.dictionaries))
        // {
          "${configDir}/NativeMessagingHosts" = lib.mkIf (cfg.nativeMessagingHosts != [ ]) {
            source = "${nativeMessagingHostsJoined}/etc/chromium/native-messaging-hosts";
            recursive = true;
          };
        }
      );
    };

in
{
  # Extensions do not work with the proprietary Google Chrome version
  # see https://github.com/nix-community/home-manager/issues/1383
  imports =
    map
      (lib.flip lib.mkRemovedOptionModule "The `extensions` option does not work on Google Chrome anymore.")
      [
        [
          "programs"
          "google-chrome"
          "extensions"
        ]
        [
          "programs"
          "google-chrome-beta"
          "extensions"
        ]
        [
          "programs"
          "google-chrome-dev"
          "extensions"
        ]
      ];

  options.programs = builtins.mapAttrs (
    browser: name: browserModule browser name (if browser == "chromium" then true else false)
  ) supportedBrowsers;

  config = lib.mkMerge (
    builtins.map (browser: browserConfig browser config.programs.${browser}) (
      builtins.attrNames supportedBrowsers
    )
  );
}
