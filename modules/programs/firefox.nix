{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.firefox;

  extensionPath = "extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";

  profiles =
    (flip mapAttrs' cfg.profiles (_: profile:
      nameValuePair "Profile${toString profile.id}" {
        Name = profile.name;
        Path = profile.path;
        IsRelative = 1;
        Default = if profile.isDefault then 1 else 0;
      })) // {
        General = {
          StartWithLastProfile = 1;
        };
      };

  profilesINI = generators.toINI {} profiles;

  mkUserJS = prefs: extraPrefs: ''
    ${concatStrings (mapAttrsToList (name: value: ''
    user_pref("${name}", ${builtins.toJSON value});
    '') prefs)}

    ${extraPrefs}
  '';

in

{
  meta.maintainers = [ maintainers.rycee ];

  options = {
    programs.firefox = {
      enable = mkEnableOption "Firefox";

      package = mkOption {
        type = types.package;
        default = pkgs.firefox-unwrapped;
        defaultText = "pkgs.firefox-unwrapped";
        description = "The unwrapped Firefox package to use.";
      };

      extensions = mkOption {
        type = types.listOf types.package;
        default = [];
        example = literalExample ''
          with pkgs.nur.repos.rycee.firefox-addons; [
            https-everywhere
            privacy-badger
          ]
        '';
        description = ''
          List of Firefox add-on packages to install. Note, it is
          necessary to manually enable these extensions inside Firefox
          after the first installation.
        '';
      };

      profiles = mkOption {
        type = types.attrsOf (types.submodule ({config, name, ...}: {
          options = {
            name = mkOption {
              type = types.str;
              default = name;
              description = "Profile name.";
            };

            id = mkOption {
              type = types.int;
              default = 0;
              description = "Profile ID.";
            };

            preferences = mkOption {
              type = types.attrs;
              default = {};
              example = {
                "browser.startup.homepage" = "https://nixos.org";
                "browser.search.region" = "GB";
                "browser.search.isUS" = false;
                "distribution.searchplugins.defaultLocale" = "en-GB";
                "general.useragent.locale" = "en-GB";
                "browser.bookmarks.showMobileBookmarks" = true;
              };
              description = "Attribute set of firefox preferences.";
            };

            extraPreferences = mkOption {
              type = types.lines;
              default = "";
              description = "Extra preferences";
            };

            customCSS = mkOption {
              type = types.lines;
              default = "";
              description = "Custom firefox CSS.";
              example = ''
                /* Hide tab bar in FF Quantum */
                @-moz-document url("chrome://browser/content/browser.xul") {
                  #TabsToolbar {
                    visibility: collapse !important;
                    margin-bottom: 21px !important;
                  }

                  #sidebar-box[sidebarcommand="treestyletab_piro_sakura_ne_jp-sidebar-action"] #sidebar-header {
                    visibility: collapse !important;
                  }
                }
              '';
            };

            path = mkOption {
              type = types.str;
              default = name;
              description = "Profile path.";
            };

            isDefault = mkOption {
              type = types.bool;
              default = config.id == 0;
              defaultText = "true if profile ID is 0";
              description = "Whether this is a default profile.";
            };
          };
        }));
        default = {};
        description = "Attribute set of firefox profiles.";
      };

      enableAdobeFlash = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the unfree Adobe Flash plugin.";
      };

      enableGoogleTalk = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the unfree Google Talk plugin. This option
          is <emphasis>deprecated</emphasis> and will only work if

          <programlisting language="nix">
          programs.firefox.package = pkgs.firefox-esr-52-unwrapped;
          </programlisting>

          and the <option>plugin.load_flash_only</option> Firefox
          option has been disabled.
        '';
      };

      enableIcedTea = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable the Java applet plugin. This option is
          <emphasis>deprecated</emphasis> and will only work if

          <programlisting language="nix">
          programs.firefox.package = pkgs.firefox-esr-52-unwrapped;
          </programlisting>

          and the <option>plugin.load_flash_only</option> Firefox
          option has been disabled.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
	assertions = [(
      let
        defaults =
          catAttrs "name" (filter (a: a.isDefault) (attrValues cfg.profiles));
      in {
        assertion = length defaults == 1;
        message =
          "Must have exactly one default firefox profile but found "
          + toString (length defaults)
          + optionalString (length defaults > 1)
              (", namely " + concatStringsSep ", " defaults);
      }
    )];

    home.packages =
      let
        # A bit of hackery to force a config into the wrapper.
        browserName = cfg.package.browserName
          or (builtins.parseDrvName cfg.package.name).name;

        fcfg = setAttrByPath [browserName] {
          enableAdobeFlash = cfg.enableAdobeFlash;
          enableGoogleTalkPlugin = cfg.enableGoogleTalk;
          icedtea = cfg.enableIcedTea;
        };

        wrapper = pkgs.wrapFirefox.override {
          config = fcfg;
        };
      in
        [ (wrapper cfg.package { }) ];

    home.file = mkMerge ([{
      ".mozilla/${extensionPath}" = mkIf (cfg.extensions != []) (
        let
          extensionsEnv = pkgs.buildEnv {
            name = "hm-firefox-extensions";
            paths = cfg.extensions;
          };
        in {
          source = "${extensionsEnv}/share/mozilla/${extensionPath}";
        }
      );

      ".mozilla/firefox/profiles.ini" = mkIf (cfg.profiles != {}) {
        text = profilesINI;
      };
    }] ++ (flip mapAttrsToList cfg.profiles (_: profile: {
      ".mozilla/firefox/${profile.path}/chrome/userChrome.css" = mkIf (profile.customCSS != "") {
        text = profile.customCSS;
      };

      ".mozilla/firefox/${profile.path}/user.js" = mkIf (profile.preferences != {} || profile.extraPreferences != "") {
        text = mkUserJS profile.preferences profile.extraPreferences;
      };
    })));
  };
}
