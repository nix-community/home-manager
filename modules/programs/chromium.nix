{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkOption
    mkEnableOption
    mkPackageOption
    types
    ;
  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;

  chromeWebStoreUpdateUrl = "https://clients2.google.com/service/update2/crx";

  mkChromiumBrowser =
    name:
    types.submodule {
      options = {
        displayName = mkOption {
          type = types.str;
          description = "Display name of the browser";
        };

        darwinDir = mkOption {
          type = types.str;
          description = "Directory path in macOS Library/Application Support for browser configuration";
        };

        linuxDir = mkOption {
          type = types.str;
          default = name;
          description = "Directory path in XDG config home for browser configuration on Linux";
        };

        supportsPlasmaSupport = mkEnableOption "KDE Plasma integration support for this browser";
      };
    };

  browserSpecs = {
    chromium = (mkChromiumBrowser "chromium") {
      displayName = "Chromium";
      darwinDir = "Chromium";
    };

    brave = (mkChromiumBrowser "brave") {
      displayName = "Brave Browser";
      darwinDir = "BraveSoftware/Brave-Browser";
      linuxDir = "BraveSoftware/Brave-Browser";
    };

    google-chrome = (mkChromiumBrowser "google-chrome") {
      displayName = "Google Chrome";
      darwinDir = "Google/Chrome";
      supportsPlasmaSupport = true;
    };

    google-chrome-beta = (mkChromiumBrowser "google-chrome-beta") {
      displayName = "Google Chrome Beta";
      darwinDir = "Google/Chrome Beta";
    };

    google-chrome-dev = (mkChromiumBrowser "google-chrome-dev") {
      displayName = "Google Chrome Dev";
      darwinDir = "Google/Chrome Dev";
    };

    vivaldi = (mkChromiumBrowser "vivaldi") {
      displayName = "Vivaldi Browser";
    };
  };

  browserModule =
    browser:
    let
      spec = browserSpecs.${browser};
      inherit (spec) displayName;
    in
    {
      enable = mkEnableOption displayName;

      package = mkPackageOption pkgs browser {
        nullable = true;
      };

      finalPackage = mkOption {
        type = types.nullOr types.package;
        readOnly = true;
        description = ''
          Resulting customized ${displayName} package.

          This includes any Home Manager customizations such as
          `commandLineArgs` or `plasmaSupport`, and can be referenced from
          other Home Manager options through
          `config.programs.${browser}.finalPackage`.
        '';
      };

      commandLineArgs = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "--enable-logging=stderr"
          "--ignore-gpu-blocklist"
        ];
        description = ''
          List of command-line arguments to be passed to ${displayName}.

          For a list of common switches, see
          [Chrome switches](https://chromium.googlesource.com/chromium/src/+/refs/heads/main/chrome/common/chrome_switches.cc).

          To search switches for other components, see
          [Chromium codesearch](https://source.chromium.org/search?q=file:switches.cc&ss=chromium%2Fchromium%2Fsrc).
        '';
      };

      dictionaries = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression ''
          [
            pkgs.hunspellDictsChromium.en_US
          ]
        '';
        description = ''
          List of ${displayName} dictionaries to install.
        '';
      };

      nativeMessagingHosts = mkOption {
        type = types.listOf types.package;
        default = [ ];
        example = literalExpression ''
          [
            pkgs.keepassxc
          ]
        '';
        description = ''
          List of ${displayName} native messaging hosts to install.
        '';
      };

      extensions = mkOption {
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
          List of ${displayName} extensions to install.
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
    }
    // lib.optionalAttrs (isLinux && spec.supportsPlasmaSupport) {
      plasmaSupport = mkEnableOption "the 'Use QT' theme for ${displayName}";

      plasmaBrowserIntegrationPackage = mkPackageOption pkgs.kdePackages "plasma-browser-integration" {
        extraDescription = "Used for the native messaging host on Linux.";
        pkgsText = "pkgs.kdePackages";
      };
    };

  browserConfig =
    browser: cfg:
    let
      spec = browserSpecs.${browser};

      packageName =
        if cfg.package == null then
          null
        else
          (cfg.package.pname or (builtins.parseDrvName cfg.package.name).name);

      isProprietaryChrome = lib.hasPrefix "google-chrome" browser;
      supportsUserExtensions = !isProprietaryChrome || isDarwin;

      configDir =
        if isDarwin then
          "Library/Application Support/" + spec.darwinDir
        else
          "${config.xdg.configHome}/" + spec.linuxDir;

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

      plasmaSupportEnabled = isLinux && spec.supportsPlasmaSupport && cfg.plasmaSupport;

      nativeMessagingHosts = lib.unique (
        cfg.nativeMessagingHosts ++ lib.optional plasmaSupportEnabled cfg.plasmaBrowserIntegrationPackage
      );

      nativeMessagingHostsJoined = pkgs.symlinkJoin {
        name = "${browser}-native-messaging-hosts";
        paths = nativeMessagingHosts;
      };

    in

    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = !(cfg.package == null && cfg.commandLineArgs != [ ]);
          message = "Cannot set `commandLineArgs` when `package` is null for ${browser}.";
        }
        {
          assertion = !(packageName != null && !builtins.hasAttr packageName browserSpecs);
          message = "Cannot set `package` to `${packageName}` for ${browser}. Use one of the packages in `browserSpecs` instead.";
        }
        {
          assertion =
            !(packageName != null && builtins.hasAttr packageName browserSpecs && packageName != browser);
          message = "Cannot set `package` to `${packageName}` for ${browser}. Use `programs.${packageName}.enable = true;` instead.";
        }
        {
          assertion = builtins.all (ext: (ext.crxPath == null) == (ext.version == null)) cfg.extensions;
          message = "Cannot set `version` without `crxPath`, or `crxPath` without `version`, for `${browser}`.";
        }
        {
          assertion = !(isProprietaryChrome && isLinux && cfg.extensions != [ ]);
          message = "Cannot set `extensions` for `${browser}` on Linux. Google Chrome only loads external extensions from system-managed directories, which Home Manager does not manage.";
        }
        {
          assertion =
            !(
              isProprietaryChrome
              && isDarwin
              && !builtins.all (
                ext: ext.crxPath == null && ext.version == null && ext.updateUrl == chromeWebStoreUpdateUrl
              ) cfg.extensions
            );
          message = "Cannot set `crxPath`, `version`, or a custom `updateUrl` for `${browser}` on Darwin. Google Chrome only supports Chrome Web Store external extensions there.";
        }
      ];

      programs.${browser}.finalPackage =
        if cfg.package == null then
          null
        else if cfg.commandLineArgs != [ ] || plasmaSupportEnabled then
          cfg.package.override (
            lib.optionalAttrs (cfg.commandLineArgs != [ ]) {
              commandLineArgs = lib.concatStringsSep " " cfg.commandLineArgs;
            }
            // lib.optionalAttrs plasmaSupportEnabled {
              plasmaSupport = true;
              inherit (pkgs) kdePackages;
            }
          )
        else
          cfg.package;

      home.packages = lib.optional (cfg.finalPackage != null) cfg.finalPackage;
      home.file =
        lib.optionalAttrs supportsUserExtensions (lib.listToAttrs (map extensionJson cfg.extensions))
        // lib.listToAttrs (map dictionary cfg.dictionaries)
        // {
          "${configDir}/NativeMessagingHosts" = lib.mkIf (nativeMessagingHosts != [ ]) {
            source = "${nativeMessagingHostsJoined}/etc/chromium/native-messaging-hosts";
            recursive = true;
          };
        };
    };

in
{
  options.programs = lib.mapAttrs (browser: _: browserModule browser) browserSpecs;

  config = lib.mkMerge lib.mapAttrsToList (
    browser: _: browserConfig browser config.programs.${browser}
  ) browserSpecs;
}
