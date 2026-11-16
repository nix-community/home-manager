{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  inherit (lib)
    catAttrs
    filter
    mkOption
    optionalAttrs
    types
    ;

  cfg = config.programs.notmuch;

  legacyDefaults = lib.versionOlder config.home.stateVersion "26.11";

  mkIniKeyValue =
    key: value:
    let
      tweakVal =
        v:
        if lib.isString v then
          v
        else if lib.isList v then
          lib.concatMapStringsSep ";" tweakVal v
        else if lib.isBool v then
          (if v then "true" else "false")
        else
          toString v;
    in
    "${key}=${tweakVal value}";

in
{
  imports =
    let
      extraConfig = lib.hm.deprecations.mkSettingsOverlay {
        inherit options;
        from = [
          "programs"
          "notmuch"
          "extraConfig"
        ];
        to = [
          "programs"
          "notmuch"
          "settings"
        ];
      };
    in
    lib.hm.deprecations.mkSettingsRenamedOptionModules
      [ "programs" "notmuch" ]
      [ "programs" "notmuch" "settings" ]
      { preserveOrder = true; }
      [
        [
          "new"
          "ignore"
        ]
        [
          "new"
          "tags"
        ]
        {
          old = [
            "maildir"
            "synchronizeFlags"
          ];
          new = [
            "maildir"
            "synchronize_flags"
          ];
        }
        {
          old = [
            "search"
            "excludeTags"
          ];
          new = [
            "search"
            "exclude_tags"
          ];
        }
      ]
    ++ [ extraConfig.module ];

  options = {
    programs.notmuch = {
      enable = lib.mkEnableOption "Notmuch mail indexer";

      package = lib.mkPackageOption pkgs "notmuch" { };

      settings = mkOption {
        type =
          let
            atom = (pkgs.formats.ini { }).lib.types.atom;
          in
          types.attrsOf (types.attrsOf (types.either atom (types.listOf atom)));
        default = { };
        example = {
          show.extra_headers = [
            "List-Id"
            "Mailing-List"
          ];
          new.tags = [ "inbox" ];
        };
        description = ''
          Native settings written to the notmuch configuration file. Lists are
          serialized as semicolon-separated values, including empty lists.
          Null settings and empty sections are omitted. Unset keys use notmuch's
          own defaults. `database.path` defaults to
          `accounts.email.maildirBasePath` when an email account is enabled,
          and notmuch-enabled email accounts supply `user` values; any
          definition of the same key replaces these. For `home.stateVersion`
          below 26.11, `database.path` has this default even without email
          accounts, and `search.exclude_tags` defaults to `deleted;spam`.
          `new.ignore`, `new.tags`, `maildir.synchronizeFlags`,
          `search.excludeTags`, and `extraConfig` under `programs.notmuch` are
          deprecated aliases into settings. Alias definitions retain their
          priorities and list ordering.
          Definitions of the same list setting concatenate unless a stronger
          priority replaces them. Unlike the old final `extraConfig` overlay,
          conflicting ordinary scalar definitions must be resolved in settings.
          Apply `lib.mkDefault` to individual settings, not to a whole section
          or the whole attribute set; section-level priorities lose to definitions
          Home Manager or the mbsync, lieer, and mujmap modules supply in
          `database`, `new`, `search`, and `user`.

          See <https://notmuchmail.org/manpages/notmuch-config-1/> for
          available settings.
        '';
      };

      hooks = {
        preNew = mkOption {
          type = types.lines;
          default = "";
          example = "mbsync --all";
          description = ''
            Bash statements run before scanning or importing new
            messages into the database.
          '';
        };

        postNew = mkOption {
          type = types.lines;
          default = "";
          example = ''
            notmuch tag +nixos -- tag:new and from:nixos1@discoursemail.com
          '';
          description = ''
            Bash statements run after new messages have been imported
            into the database and initial tags have been applied.
          '';
        };

        postInsert = mkOption {
          type = types.lines;
          default = "";
          description = ''
            Bash statements run after a message has been inserted
            into the database and initial tags have been applied.
          '';
        };
      };
    };

    accounts.email.accounts = mkOption {
      type =
        with types;
        attrsOf (submodule {
          options.notmuch.enable = lib.mkEnableOption "notmuch indexing";
        });
    };
  };

  config = lib.mkIf cfg.enable {
    programs.notmuch.settings = {
      database.path = lib.mkIf (
        legacyDefaults || lib.any (account: account.enable) (lib.attrValues config.accounts.email.accounts)
      ) (lib.mkOptionDefault config.accounts.email.maildirBasePath);
      search.exclude_tags = lib.mkIf legacyDefaults (
        lib.mkOptionDefault [
          "deleted"
          "spam"
        ]
      );
      user =
        let
          accounts = filter (a: a.enable && a.notmuch.enable) (lib.attrValues config.accounts.email.accounts);
          primary = filter (a: a.primary) accounts;
          secondaries = filter (a: !a.primary) accounts;
        in
        lib.mkIf (accounts != [ ]) {
          name = lib.mkOptionDefault (catAttrs "realName" primary);
          primary_email = lib.mkOptionDefault (catAttrs "address" primary);
          other_email = lib.mkOptionDefault (
            map (email: email.address or email) (
              lib.flatten (
                catAttrs "aliases" primary ++ catAttrs "address" secondaries ++ catAttrs "aliases" secondaries
              )
            )
          );
        };
    };

    assertions =
      let
        isSet = value: value != null && value != [ ];
      in
      [
        {
          assertion = isSet (cfg.settings.user.name or null);
          message = "notmuch: Must have a user name set.";
        }
        {
          assertion = isSet (cfg.settings.user.primary_email or null);
          message = "notmuch: Must have a user primary email address set.";
        }
      ];

    home.packages = [ cfg.package ];

    home.sessionVariables = {
      NOTMUCH_CONFIG = "${config.xdg.configHome}/notmuch/default/config";
      NMBGIT = "${config.xdg.dataHome}/notmuch/nmbug";
    };

    xdg.configFile =
      let
        hook = name: cmds: {
          "notmuch/default/hooks/${name}".source = pkgs.writeShellScript name ''
            export PATH="${cfg.package}/bin''${PATH:+:}$PATH"
            export NOTMUCH_CONFIG="${config.xdg.configHome}/notmuch/default/config"
            export NMBGIT="${config.xdg.dataHome}/notmuch/nmbug"

            ${cmds}
          '';
        };
      in
      {
        "notmuch/default/config".text =
          let
            toIni = lib.generators.toINI { mkKeyValue = mkIniKeyValue; };
          in
          ''
            # Generated by Home Manager.

          ''
          + toIni (
            lib.filterAttrs (_: section: section != { }) (
              lib.mapAttrs (_: lib.filterAttrs (_: value: value != null)) cfg.settings
            )
          );
      }
      // optionalAttrs (cfg.hooks.preNew != "") (hook "pre-new" cfg.hooks.preNew)
      // optionalAttrs (cfg.hooks.postNew != "") (hook "post-new" cfg.hooks.postNew)
      // optionalAttrs (cfg.hooks.postInsert != "") (hook "post-insert" cfg.hooks.postInsert);
  };
}
