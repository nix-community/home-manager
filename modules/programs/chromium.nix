{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) literalExpression mkOption types;

  chromeWebStoreUpdateUrl = "https://clients2.google.com/service/update2/crx";

  supportedBrowsers = {
    chromium = "Chromium";
    google-chrome = "Google Chrome";
    google-chrome-beta = "Google Chrome Beta";
    google-chrome-dev = "Google Chrome Dev";
    brave = "Brave Browser";
    vivaldi = "Vivaldi Browser";
  };

  plasmaSupportedBrowsers = [
    "google-chrome"
  ];

  browserModule =
    browser: name: visible:
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
    // lib.optionalAttrs (lib.elem browser plasmaSupportedBrowsers) {
      plasmaSupport = mkOption {
        inherit visible;
        type = types.bool;
        default = false;
        example = true;
        description = "Whether to enable the 'Use QT' theme for ${name}.";
      };
    }
    // {
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
    }
    // {
      extensions = mkOption {
        inherit visible;
        type =
          let
            extensionType = types.submodule {
              options = {
                id = mkOption {
                  type = types.strMatching "[a-zA-Z]{32}";
                  description = ''
                    The extension's ID from the Chrome Web Store url or the unpacked crx.
                  '';
                  default = "";
                };

                updateUrl = mkOption {
                  type = types.str;
                  default = chromeWebStoreUpdateUrl;
                  description = ''
                    URL of the extension's update manifest XML file.

                    Proprietary Google Chrome on macOS only supports the Chrome
                    Web Store update URL.
                  '';
                };

                crxPath = mkOption {
                  type = types.nullOr types.path;
                  default = null;
                  description = ''
                    Path to the extension's crx file.

                    Proprietary Google Chrome on macOS does not support local
                    crx installation.
                  '';
                };

                version = mkOption {
                  type = types.nullOr types.str;
                  default = null;
                  description = ''
                    The extension's version, required for local installation.

                    Proprietary Google Chrome on macOS does not support local
                    crx installation.
                  '';
                };
              };
            };
          in
          types.listOf (types.coercedTo types.str (v: { id = v; }) extensionType);
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

          When using `pkgs.ungoogled-chromium` on Linux, prefer `crxPath` and
          `version`. The default Chrome Web Store update URL is generally not
          sufficient there.

          Proprietary Google Chrome on macOS only supports extensions from the
          Chrome Web Store.
        '';
      };
    };

  browserConfig =
    browser: cfg:
    let
      # Native messaging host manifests must follow the actual browser package
      # directory layout, not just the Home Manager option namespace.
      effectiveBrowser =
        let
          packageName =
            if cfg.package == null then
              browser
            else
              (cfg.package.pname or (builtins.parseDrvName cfg.package.name).name);
        in
        if builtins.hasAttr packageName supportedBrowsers then packageName else browser;

      isProprietaryChrome = lib.hasPrefix "google-chrome" effectiveBrowser;
      supportsUserExtensions = !isProprietaryChrome || pkgs.stdenv.isDarwin;

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
          "Library/Application Support/" + (darwinDirs."${effectiveBrowser}" or effectiveBrowser)
        else
          "${config.xdg.configHome}/" + (linuxDirs."${effectiveBrowser}" or effectiveBrowser);

      extensionJson =
        ext:
        assert ext.crxPath != null -> ext.version != null;
        {
          name = "${configDir}/External Extensions/${ext.id}.json";
          value.text = builtins.toJSON (
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
        name = "${effectiveBrowser}-native-messaging-hosts";
        paths = cfg.nativeMessagingHosts;
      };

    in

    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !(cfg.package == null && cfg.commandLineArgs != [ ]);
          message = "Cannot set `commandLineArgs` when `package` is null for ${browser}.";
        }
        {
          assertion = !(isProprietaryChrome && pkgs.stdenv.isLinux && cfg.extensions != [ ]);
          message = "Cannot set `extensions` for `${effectiveBrowser}` on Linux. Google Chrome only loads external extensions from system-managed directories, which Home Manager does not manage.";
        }
        {
          assertion =
            !(
              isProprietaryChrome
              && pkgs.stdenv.isDarwin
              && !builtins.all (
                ext: ext.crxPath == null && ext.version == null && ext.updateUrl == chromeWebStoreUpdateUrl
              ) cfg.extensions
            );
          message = "Cannot set `crxPath`, `version`, or a custom `updateUrl` for `${effectiveBrowser}` on Darwin. Google Chrome only supports Chrome Web Store external extensions there.";
        }
      ];

      programs.${browser}.finalPackage =
        if cfg.package == null then
          null
        else if cfg.commandLineArgs != [ ] || (cfg.plasmaSupport or false) then
          cfg.package.override (
            lib.optionalAttrs (cfg.commandLineArgs != [ ]) {
              commandLineArgs = lib.concatStringsSep " " cfg.commandLineArgs;
            }
            // lib.optionalAttrs (cfg.plasmaSupport or false) {
              plasmaSupport = true;
              inherit (pkgs) kdePackages;
            }
          )
        else
          cfg.package;

      home.packages = lib.mkIf (cfg.finalPackage != null) [
        cfg.finalPackage
      ];
      home.file =
        lib.optionalAttrs supportsUserExtensions (lib.listToAttrs (map extensionJson cfg.extensions))
        // lib.listToAttrs (map dictionary cfg.dictionaries)
        // {
          "${configDir}/NativeMessagingHosts" = lib.mkIf (cfg.nativeMessagingHosts != [ ]) {
            source = "${nativeMessagingHostsJoined}/etc/chromium/native-messaging-hosts";
            recursive = true;
          };
        };
    };

in
{
  options.programs = builtins.mapAttrs (
    browser: name: browserModule browser name (if browser == "chromium" then true else false)
  ) supportedBrowsers;

  config = lib.mkMerge (
    map (browser: browserConfig browser config.programs.${browser}) (
      builtins.attrNames supportedBrowsers
    )
  );
}
