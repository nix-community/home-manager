{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs.stdenv.hostPlatform) isDarwin;

  cfg = config.programs.thunderbird;

  thunderbirdJson = types.attrsOf (pkgs.formats.json { }).type // {
    description =
      "Thunderbird preference (int, bool, string, and also attrs, list, float as a JSON string)";
  };

  # The extensions path shared by all profiles.
  extensionPath = "extensions/{ec8030f7-c20a-464f-9b0e-13a3a9e97384}";

  moduleName = "programs.thunderbird";

  enabledAccounts = attrValues
    (filterAttrs (_: a: a.thunderbird.enable) config.accounts.email.accounts);

  enabledAccountsWithId =
    map (a: a // { id = builtins.hashString "sha256" a.name; }) enabledAccounts;

  thunderbirdConfigPath =
    if isDarwin then "Library/Thunderbird" else ".thunderbird";

  thunderbirdProfilesPath = if isDarwin then
    "${thunderbirdConfigPath}/Profiles"
  else
    thunderbirdConfigPath;

  profilesWithId =
    imap0 (i: v: v // { id = toString i; }) (attrValues cfg.profiles);

  profilesIni = foldl recursiveUpdate {
    General = {
      StartWithLastProfile = 1;
    } // lib.optionalAttrs (cfg.profileVersion != null) {
      Version = cfg.profileVersion;
    };
  } (flip map profilesWithId (profile: {
    "Profile${profile.id}" = {
      Name = profile.name;
      Path = if isDarwin then "Profiles/${profile.name}" else profile.name;
      IsRelative = 1;
      Default = if profile.isDefault then 1 else 0;
    };
  }));

  getId = account: address:
    if address == account.address then
      account.id
    else
      (builtins.hashString "sha256" (if (builtins.isString address) then
        address
      else
        (address.address + address.realName)));

  toThunderbirdIdentity = account: address:
    # For backwards compatibility, the primary address reuses the account ID.
    let
      id = getId account address;
      addressIsString = builtins.isString address;
    in {
      "mail.identity.id_${id}.fullName" =
        if addressIsString then account.realName else address.realName;
      "mail.identity.id_${id}.useremail" =
        if addressIsString then address else address.address;
      "mail.identity.id_${id}.valid" = true;
      "mail.identity.id_${id}.htmlSigText" =
        if account.signature.showSignature == "none" then
          ""
        else
          account.signature.text;
    } // optionalAttrs (account.gpg != null) {
      "mail.identity.id_${id}.attachPgpKey" = false;
      "mail.identity.id_${id}.autoEncryptDrafts" = true;
      "mail.identity.id_${id}.e2etechpref" = 0;
      "mail.identity.id_${id}.encryptionpolicy" =
        if account.gpg.encryptByDefault then 2 else 0;
      "mail.identity.id_${id}.is_gnupg_key_id" = true;
      "mail.identity.id_${id}.last_entered_external_gnupg_key_id" =
        account.gpg.key;
      "mail.identity.id_${id}.openpgp_key_id" = account.gpg.key;
      "mail.identity.id_${id}.protectSubject" = true;
      "mail.identity.id_${id}.sign_mail" = account.gpg.signByDefault;
    } // optionalAttrs (account.smtp != null) {
      "mail.identity.id_${id}.smtpServer" = "smtp_${account.id}";
    } // account.thunderbird.perIdentitySettings id;

  toThunderbirdAccount = account: profile:
    let
      id = account.id;
      addresses = [ account.address ] ++ account.aliases;
    in {
      "mail.account.account_${id}.identities" = concatStringsSep ","
        (map (address: "id_${getId account address}") addresses);
      "mail.account.account_${id}.server" = "server_${id}";
    } // optionalAttrs account.primary {
      "mail.accountmanager.defaultaccount" = "account_${id}";
    } // optionalAttrs (account.imap != null) {
      "mail.server.server_${id}.directory" =
        "${thunderbirdProfilesPath}/${profile.name}/ImapMail/${id}";
      "mail.server.server_${id}.directory-rel" = "[ProfD]ImapMail/${id}";
      "mail.server.server_${id}.hostname" = account.imap.host;
      "mail.server.server_${id}.login_at_startup" = true;
      "mail.server.server_${id}.name" = account.name;
      "mail.server.server_${id}.port" =
        if (account.imap.port != null) then account.imap.port else 143;
      "mail.server.server_${id}.socketType" = if !account.imap.tls.enable then
        0
      else if account.imap.tls.useStartTls then
        2
      else
        3;
      "mail.server.server_${id}.type" = "imap";
      "mail.server.server_${id}.userName" = account.userName;
    } // optionalAttrs (account.smtp != null) {
      "mail.smtpserver.smtp_${id}.authMethod" = 3;
      "mail.smtpserver.smtp_${id}.hostname" = account.smtp.host;
      "mail.smtpserver.smtp_${id}.port" =
        if (account.smtp.port != null) then account.smtp.port else 587;
      "mail.smtpserver.smtp_${id}.try_ssl" = if !account.smtp.tls.enable then
        0
      else if account.smtp.tls.useStartTls then
        2
      else
        3;
      "mail.smtpserver.smtp_${id}.username" = account.userName;
    } // optionalAttrs (account.smtp != null && account.primary) {
      "mail.smtp.defaultserver" = "smtp_${id}";
    } // builtins.foldl' (a: b: a // b) { }
    (builtins.map (address: toThunderbirdIdentity account address) addresses)
    // account.thunderbird.settings id;

  toThunderbirdFeed = feed: profile:
    let id = feed.id;
    in {
      "mail.account.account_${id}.server" = "server_${id}";
      "mail.server.server_${id}.name" = feed.name;
      "mail.server.server_${id}.type" = "rss";
      "mail.server.server_${id}.directory" =
        "${thunderbirdProfilesPath}/${profile.name}/Mail/Feeds-${id}";
      "mail.server.server_${id}.directory-rel" = "[ProfD]Mail/Feeds-${id}";
      "mail.server.server_${id}.hostname" = "Feeds-${id}";
    };

  mkUserJs = prefs: extraPrefs: ''
    // Generated by Home Manager.

    ${concatStrings (mapAttrsToList (name: value: ''
      user_pref("${name}", ${builtins.toJSON value});
    '') prefs)}
    ${extraPrefs}
  '';

  mkFilterToIniString = f:
    if f.text == null then
      ''
        name="${f.name}"
        enabled="${if f.enabled then "yes" else "no"}"
        type="${f.type}"
        action="${f.action}"
      '' + optionalString (f.actionValue != null) ''
        actionValue="${f.actionValue}"
      '' + ''
        condition="${f.condition}"
      '' + optionalString (f.extraConfig != null) f.extraConfig
    else
      f.text;

  mkFilterListToIni = filters:
    ''
      version="9"
      logging="no"
    '' + concatStrings (map (f: mkFilterToIniString f) filters);

  getEmailAccountsForProfile = profileName: accounts:
    (filter (a:
      a.thunderbird.profiles == [ ]
      || any (p: p == profileName) a.thunderbird.profiles) accounts);
in {
  meta.maintainers = with hm.maintainers; [ d-dervishi jkarlson ];

  options = {
    programs.thunderbird = {
      enable = mkEnableOption "Thunderbird";

      package = mkOption {
        type = types.package;
        default = pkgs.thunderbird;
        defaultText = literalExpression "pkgs.thunderbird";
        example = literalExpression "pkgs.thunderbird-91";
        description = "The Thunderbird package to use.";
      };

      profileVersion = mkOption {
        internal = true;
        type = types.nullOr types.ints.unsigned;
        default = if isDarwin then null else 2;
        description = "profile version, set null for nix-darwin";
      };

      nativeMessagingHosts = mkOption {
        visible = true;
        type = types.listOf types.package;
        default = [ ];
        description = ''
          Additional packages containing native messaging hosts that should be
          made available to Thunderbird extensions.
        '';
      };

      profiles = mkOption {
        type = with types;
          attrsOf (submodule ({ config, name, ... }: {
            options = {
              name = mkOption {
                type = types.str;
                default = name;
                readOnly = true;
                description = "This profile's name.";
              };

              isDefault = mkOption {
                type = types.bool;
                default = false;
                example = true;
                description = ''
                  Whether this is a default profile. There must be exactly one
                  default profile.
                '';
              };

              feedAccounts = mkOption {
                type = types.attrsOf (submodule ({ config, name, ... }: {
                  options = {
                    name = mkOption {
                      type = types.str;
                      default = name;
                      readOnly = true;
                      description = "This feed account's name.";
                    };
                  };
                }));
                default = { };
                description = ''
                  Attribute set of feed accounts. Feeds themselves have to be
                  managed through Thunderbird's settings. This option allows
                  feeds to coexist with declaratively managed email accounts.
                '';
              };

              settings = mkOption {
                type = thunderbirdJson;
                default = { };
                example = literalExpression ''
                  {
                    "mail.spellcheck.inline" = false;
                    "mailnews.database.global.views.global.columns" = {
                      selectCol = {
                        visible = false;
                        ordinal = 1;
                      };
                      threadCol = {
                        visible = true;
                        ordinal = 2;
                      };
                    };
                  }
                '';
                description = ''
                  Preferences to add to this profile's
                  {file}`user.js`.
                '';
              };

              withExternalGnupg = mkOption {
                type = types.bool;
                default = false;
                example = true;
                description = "Allow using external GPG keys with GPGME.";
              };

              userChrome = mkOption {
                type = types.lines;
                default = "";
                description = "Custom Thunderbird user chrome CSS.";
                example = ''
                  /* Hide tab bar in Thunderbird */
                  #tabs-toolbar {
                    visibility: collapse !important;
                  }
                '';
              };

              userContent = mkOption {
                type = types.lines;
                default = "";
                description = "Custom Thunderbird user content CSS.";
                example = ''
                  /* Hide scrollbar on Thunderbird pages */
                  *{scrollbar-width:none !important}
                '';
              };

              extraConfig = mkOption {
                type = types.lines;
                default = "";
                description = ''
                  Extra preferences to add to {file}`user.js`.
                '';
              };

              search = mkOption {
                type = types.submodule (args:
                  import ./firefox/profiles/search.nix {
                    inherit (args) config;
                    inherit lib pkgs;
                    appName = "Thunderbird";
                    package = cfg.package;
                    modulePath =
                      [ "programs" "thunderbird" "profiles" name "search" ];
                    profilePath = name;
                  });
                default = { };
                description = "Declarative search engine configuration.";
              };

              extensions = mkOption {
                type = types.listOf types.package;
                default = [ ];
                example = literalExpression ''
                  [
                    pkgs.some-thunderbird-extension
                  ]
                '';
                description = ''
                  List of ${name} add-on packages to install for this profile.

                  Note that it is necessary to manually enable extensions
                  inside ${name} after the first installation.

                  To automatically enable extensions add
                  `"extensions.autoDisableScopes" = 0;`
                  to
                  [{option}`${moduleName}.profiles.<profile>.settings`](#opt-${moduleName}.profiles._name_.settings)
                '';
              };
            };
          }));
        description = "Attribute set of Thunderbird profiles.";
      };

      settings = mkOption {
        type = thunderbirdJson;
        default = { };
        example = literalExpression ''
          {
            "general.useragent.override" = "";
            "privacy.donottrackheader.enabled" = true;
          }
        '';
        description = ''
          Attribute set of Thunderbird preferences to be added to
          all profiles.
        '';
      };

      darwinSetupWarning = mkOption {
        type = types.bool;
        default = true;
        example = false;
        visible = isDarwin;
        readOnly = !isDarwin;
        description = ''
          Warn to set environment variables before using this module. Only
          relevant on Darwin.
        '';
      };
    };

    accounts.email.accounts = mkOption {
      type = with types;
        attrsOf (submodule ({ config, ... }: {
          config.thunderbird = {
            settings = lib.mkIf (config.flavor == "gmail.com") (id: {
              "mail.smtpserver.smtp_${id}.authMethod" =
                mkOptionDefault 10; # 10 = OAuth2
              "mail.server.server_${id}.authMethod" =
                mkOptionDefault 10; # 10 = OAuth2
              "mail.server.server_${id}.socketType" =
                mkOptionDefault 3; # SSL/TLS
              "mail.server.server_${id}.is_gmail" =
                mkOptionDefault true; # handle labels, trash, etc
            });
          };
          options.thunderbird = {
            enable =
              mkEnableOption "the Thunderbird mail client for this account";

            profiles = mkOption {
              type = with types; listOf str;
              default = [ ];
              example = literalExpression ''
                [ "profile1" "profile2" ]
              '';
              description = ''
                List of Thunderbird profiles for which this account should be
                enabled. If this list is empty (the default), this account will
                be enabled for all declared profiles.
              '';
            };

            settings = mkOption {
              type = with types; functionTo (attrsOf (oneOf [ bool int str ]));
              default = _: { };
              defaultText = literalExpression "_: { }";
              example = literalExpression ''
                id: {
                  "mail.server.server_''${id}.check_new_mail" = false;
                };
              '';
              description = ''
                Extra settings to add to this Thunderbird account configuration.
                The {var}`id` given as argument is an automatically
                generated account identifier.
              '';
            };

            perIdentitySettings = mkOption {
              type = with types; functionTo (attrsOf (oneOf [ bool int str ]));
              default = _: { };
              defaultText = literalExpression "_: { }";
              example = literalExpression ''
                id: {
                  "mail.identity.id_''${id}.protectSubject" = false;
                  "mail.identity.id_''${id}.autoEncryptDrafts" = false;
                };
              '';
              description = ''
                Extra settings to add to each identity of this Thunderbird
                account configuration. The {var}`id` given as
                argument is an automatically generated identifier.
              '';
            };

            messageFilters = mkOption {
              type = with types;
                listOf (submodule {
                  options = {
                    name = mkOption {
                      type = str;
                      description = "Name for the filter.";
                    };
                    enabled = mkOption {
                      type = bool;
                      default = true;
                      description = "Whether this filter is currently active.";
                    };
                    type = mkOption {
                      type = str;
                      description = "Type for this filter.";
                    };
                    action = mkOption {
                      type = str;
                      description = "Action to perform on matched messages.";
                    };
                    actionValue = mkOption {
                      type = nullOr str;
                      default = null;
                      description =
                        "Argument passed to the filter action, e.g. a folder path.";
                    };
                    condition = mkOption {
                      type = str;
                      description = "Condition to match messages against.";
                    };
                    extraConfig = mkOption {
                      type = nullOr str;
                      default = null;
                      description = "Extra settings to apply to the filter";
                    };
                    text = mkOption {
                      type = nullOr str;
                      default = null;
                      description = ''
                        The raw text of the filter.
                        Note that this will override all other options.
                      '';
                    };
                  };
                });
              default = [ ];
              defaultText = literalExpression "[ ]";
              example = literalExpression ''
                [
                  {
                    name = "Mark as Read on Archive";
                    enabled = true;
                    type = "128";
                    action = "Mark read";
                    condition = "ALL";
                  }
                ]
              '';
              description = ''
                List of message filters to add to this Thunderbird account
                configuration.
              '';
            };
          };
        }));
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (let defaults = catAttrs "name" (filter (a: a.isDefault) profilesWithId);
      in {
        assertion = cfg.profiles == { } || length defaults == 1;
        message = "Must have exactly one default Thunderbird profile but found "
          + toString (length defaults) + optionalString (length defaults > 1)
          (", namely " + concatStringsSep "," defaults);
      })

      (let
        profiles = catAttrs "name" profilesWithId;
        selectedProfiles =
          concatMap (a: a.thunderbird.profiles) enabledAccounts;
      in {
        assertion = (intersectLists profiles selectedProfiles)
          == selectedProfiles;
        message = "Cannot enable an account for a non-declared profile. "
          + "The declared profiles are " + (concatStringsSep "," profiles)
          + ", but the used profiles are "
          + (concatStringsSep "," selectedProfiles);
      })
    ];

    warnings = optional (isDarwin && cfg.darwinSetupWarning) ''
      Thunderbird packages are not yet supported on Darwin. You can still use
      this module to manage your accounts and profiles by setting
      'programs.thunderbird.package' to a dummy value, for example using
      'pkgs.runCommand'.
    '';

    home.packages = [ cfg.package ]
      ++ optional (any (p: p.withExternalGnupg) (attrValues cfg.profiles))
      pkgs.gpgme;

    mozilla.thunderbirdNativeMessagingHosts = [
      cfg.package # package configured native messaging hosts (entire mail app actually)
    ] ++ cfg.nativeMessagingHosts; # user configured native messaging hosts

    home.file = mkMerge ([{
      "${thunderbirdConfigPath}/profiles.ini" =
        mkIf (cfg.profiles != { }) { text = generators.toINI { } profilesIni; };
    }] ++ flip mapAttrsToList cfg.profiles (name: profile: {
      "${thunderbirdProfilesPath}/${name}/chrome/userChrome.css" =
        mkIf (profile.userChrome != "") { text = profile.userChrome; };

      "${thunderbirdProfilesPath}/${name}/chrome/userContent.css" =
        mkIf (profile.userContent != "") { text = profile.userContent; };

      "${thunderbirdProfilesPath}/${name}/user.js" = let
        emailAccounts = getEmailAccountsForProfile name enabledAccountsWithId;

        smtp = filter (a: a.smtp != null) emailAccounts;

        feedAccounts =
          map (f: f // { id = builtins.hashString "sha256" f.name; })
          (attrValues profile.feedAccounts);

        accounts = emailAccounts ++ feedAccounts;
      in {
        text = mkUserJs (builtins.foldl' (a: b: a // b) { } ([
          cfg.settings

          (optionalAttrs (length accounts != 0) {
            "mail.accountmanager.accounts" =
              concatStringsSep "," (map (a: "account_${a.id}") accounts);
          })

          (optionalAttrs (length smtp != 0) {
            "mail.smtpservers" =
              concatStringsSep "," (map (a: "smtp_${a.id}") smtp);
          })

          { "mail.openpgp.allow_external_gnupg" = profile.withExternalGnupg; }

          profile.settings
        ] ++ (map (a: toThunderbirdAccount a profile) emailAccounts)
          ++ (map (f: toThunderbirdFeed f profile) feedAccounts)))
          profile.extraConfig;
      };

      "${thunderbirdProfilesPath}/${name}/search.json.mozlz4" =
        mkIf (profile.search.enable) {
          enable = profile.search.enable;
          force = profile.search.force;
          source = profile.search.file;
        };

      "${thunderbirdProfilesPath}/${name}/extensions" =
        mkIf (profile.extensions != [ ]) {
          source = let
            extensionsEnvPkg = pkgs.buildEnv {
              name = "hm-thunderbird-extensions";
              paths = profile.extensions;
            };
          in "${extensionsEnvPkg}/share/mozilla/${extensionPath}";
          recursive = true;
          force = true;
        };
    }) ++ (mapAttrsToList (name: profile:
      let
        emailAccountsWithFilters =
          (filter (a: a.thunderbird.messageFilters != [ ])
            (getEmailAccountsForProfile name enabledAccountsWithId));
      in (builtins.listToAttrs (map (a: {
        name =
          "${thunderbirdProfilesPath}/${name}/ImapMail/${a.id}/msgFilterRules.dat";
        value = { text = mkFilterListToIni a.thunderbird.messageFilters; };
      }) emailAccountsWithFilters))) cfg.profiles));
  };
}
