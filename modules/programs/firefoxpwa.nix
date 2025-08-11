{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.programs.firefoxpwa;

  jsonFmt = pkgs.formats.json { };

  inherit (pkgs.stdenv.hostPlatform) isLinux;

  sites = lib.concatMapAttrs (_: profile: profile.sites) cfg.profiles;

  mkUlidAssertions =
    path:
    lib.concatMap (
      { name, value }:
      let
        length = 26;
        allowed = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";
        disallowed = lib.subtractLists (lib.stringToCharacters allowed) (lib.stringToCharacters name);
      in
      [
        {
          assertion = builtins.stringLength name == length;
          message = ''
            ULID '${name}' at 'programs.firefoxpwa.${lib.showOption path}' must be 26 characters, but is
            ${toString (builtins.stringLength name)} characters long.
          '';
        }
        {
          assertion = disallowed == [ ];
          message = ''
            ULID '${name}' at 'programs.firefoxpwa.profiles' must only contain characters
            '${allowed}', but contains '${lib.concatStrings disallowed}'.
          '';
        }
      ]
    ) (lib.attrsToList (lib.attrByPath path null cfg));
in
{
  meta.maintainers = [ lib.maintainers.bricked ];

  options.programs.firefoxpwa = {
    enable = lib.mkEnableOption "Progressive Web Apps for Firefox";

    package = lib.mkPackageOption pkgs "firefoxpwa" { nullable = true; };

    settings = lib.mkOption {
      type = jsonFmt.type;
      default = { };
      description = ''
        Settings to be written to the configuration file. See
        <https://github.com/filips123/PWAsForFirefox/blob/cb4fc76873cc51129d9290754768e6a340c521b2/native/src/storage.rs#L61-L77>
        for a list of available options.
      '';
    };

    profiles = lib.mkOption {
      default = { };
      description = ''
        Attribute set of profile options. The keys of that attribute set consist of
        ULIDs. A ULID is made of 26 characters, each of which is one of
        '0123456789ABCDEFGHJKMNPQRSTVWXYZ' (Excluding I, L, O and U). See
        <https://github.com/ulid/spec?tab=readme-ov-file#canonical-string-representation>.
      '';
      example = lib.literalExpression ''
        {
          "0123456789ABCDEFGHJKMNPQRSTVWXYZ".sites."ZYXWVTSRQPNMKJHGFEDCBA9876543210" = {
            name = "MDN Web Docs";
            url = "https://developer.mozilla.org/";
            manifestUrl = "https://developer.mozilla.org/manifest.f42880861b394dd4dc9b.json";
            desktopEntry.icon = pkgs.fetchurl {
              url = "https://developer.mozilla.org/favicon-192x192.png";
              sha256 = "0p8zgf2ba48l2pq1gjcffwzmd9kfmj9qc0v7zpwf2qd54fndifxr";
            };
          };
        }
      '';

      type = lib.types.attrsOf (
        lib.types.submodule (
          profile@{ config, name, ... }:

          {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = name;
                description = "Name of the profile.";
              };
              sites = lib.mkOption {
                default = { };
                description = ''
                  Attribute set of site options for this profile. The keys of that attribute set
                  consist of ULIDs. A ULID is made of 26 characters, each of which is one of
                  '0123456789ABCDEFGHJKMNPQRSTVWXYZ' (Excluding I, L, O and U). See
                  <https://github.com/ulid/spec?tab=readme-ov-file#canonical-string-representation>.
                  Site ULIDs must be unique across profiles.
                '';

                type = lib.types.attrsOf (
                  lib.types.submodule (
                    { config, name, ... }:

                    {
                      options = {
                        name = lib.mkOption {
                          type = lib.types.str;
                          default = name;
                          description = "Name of the site.";
                          example = "MDN Web Docs";
                        };
                        url = lib.mkOption {
                          type = lib.types.str;
                          description = "Start URL of the site.";
                          example = "https://developer.mozilla.org/";
                        };
                        manifestUrl = lib.mkOption {
                          type = lib.types.str;
                          description = "URL of the site's web app manifest.";
                          example = "https://developer.mozilla.org/manifest.f42880861b394dd4dc9b.json";
                        };
                        desktopEntry = {
                          enable = lib.mkOption {
                            type = lib.types.bool;
                            defaultText = "true if host platform is Linux";
                            description = "Whether to enable the desktop entry for this site.";
                          };
                          icon = lib.mkOption {
                            type = with lib.types; nullOr (either str path);
                            default = null;
                            description = "Icon to display in file manager, menus, etc.";
                            example = lib.literalExpression ''
                              pkgs.fetchurl {
                                url = "https://developer.mozilla.org/favicon-192x192.png";
                                sha256 = "0p8zgf2ba48l2pq1gjcffwzmd9kfmj9qc0v7zpwf2qd54fndifxr";
                              }
                            '';
                          };
                          categories = lib.mkOption {
                            type = with lib.types; nullOr (listOf str);
                            default = null;
                            description = "Categories in which the entry should be shown in a menu.";
                          };
                        };
                        settings = lib.mkOption {
                          type = jsonFmt.type;
                          default = { };
                          description = ''
                            Settings for this site. See
                            <https://github.com/filips123/PWAsForFirefox/blob/cb4fc76873cc51129d9290754768e6a340c521b2/native/src/components/site.rs#L98-L115>
                            for a list of available options.
                          '';
                          example = {
                            config.manifest_url = "https://developer.mozilla.org/manifest.f42880861b394dd4dc9b.json";
                          };
                        };
                      };

                      config = {
                        desktopEntry.enable = lib.mkDefault isLinux;
                        settings = {
                          ulid = name;
                          profile = profile.name;
                          config = {
                            name = config.name;
                            document_url = config.url;
                            manifest_url = config.manifestUrl;
                          };
                          manifest = {
                            name = config.name;
                            start_url = config.url;
                          };
                        };
                      };
                    }
                  )
                );
              };
              settings = lib.mkOption {
                type = jsonFmt.type;
                default = { };
                description = ''
                  Settings for this profile. See
                  <https://github.com/filips123/PWAsForFirefox/blob/cb4fc76873cc51129d9290754768e6a340c521b2/native/src/components/profile.rs#L13-L34>
                  for a list of available options.
                '';
              };
            };

            config.settings = {
              ulid = name;
              name = config.name;
              sites = builtins.attrNames config.sites;
            };
          }
        )
      );
    };
  };

  config = lib.mkIf cfg.enable {
    assertions =
      mkUlidAssertions [ "profiles" ]
      ++ lib.concatMap (
        name:
        mkUlidAssertions [
          "profiles"
          name
          "sites"
        ]
      ) (builtins.attrNames cfg.profiles)
      ++ map (
        name:
        let
          profiles = builtins.attrNames (lib.filterAttrs (_: profile: profile.sites ? ${name}) cfg.profiles);
        in
        {
          assertion = builtins.length profiles == 1;
          message = ''
            Site with ULID '${name}' must be present in exactly one profile, but is present
            in ${toString (builtins.length profiles)} profiles, namely ${
              lib.concatMapStringsSep ", " (x: "'${x}'") profiles
            }.
          '';
        }
      ) (builtins.attrNames sites);

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.dataFile."firefoxpwa/config.json" = lib.mkIf (cfg.settings != { }) {
      text = lib.generators.toJSON { } cfg.settings;
    };

    xdg.desktopEntries = lib.mkMerge (
      lib.mapAttrsToList (name: site: {
        "FFPWA-${name}" = lib.mkIf site.desktopEntry.enable {
          inherit (site.desktopEntry) icon categories;
          name = site.settings.manifest.name;
          exec = "firefoxpwa site launch ${name} --protocol %u";
          terminal = false;
        };
      }) sites
    );

    programs.firefoxpwa.settings = {
      profiles = builtins.mapAttrs (_: profile: profile.settings) cfg.profiles;
      sites = builtins.mapAttrs (_: site: site.settings) sites;
    };
  };
}
