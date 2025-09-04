{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption;
in
{
  options = {
    programs.pimsync = {
      enable = lib.mkEnableOption "pimsync";

      package = lib.mkPackageOption pkgs "pimsync" { };

      statusPath = mkOption {
        type = types.str;
        default = "${config.xdg.dataHome}/pimsync/status";
        defaultText = lib.literalExpression "\${config.xdg.dataHome}/pimsync/status";
        description = ""; # TODO: Describe this
      };

      defaults = mkOption {
        description = ''
          Global defaults for account-specific settings. See [] (#opt-accounts.calendar.accounts._name_.pimsync) and [] (#opt-accounts.contacts.accounts._name_.pimsync)
        '';
        default = { };
        type = types.submodule {
          options = {
            conflictResolution = mkOption {
              type = types.nullOr (
                types.oneOf [
                  (types.enum [
                    "keepLocal"
                    "keepRemote"
                  ])
                  (types.listOf types.str)
                ]
              );
              default = null;
              example = [
                "cmd"
                "nvim"
                "-d"
              ];
              description = ""; # TODO: Description
            };

            onEmpty = mkOption {
              type = types.nullOr (
                types.enum [
                  "skip"
                  "sync"
                ]
              );
              default = "skip";
              description = ""; # TODO: Description
            };

            onDelete = mkOption {
              type = types.nullOr (
                types.enum [
                  "skip"
                  "sync"
                ]
              );
              default = "sync";
              description = ""; # TODO: Description
            };

            userAgent = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = ""; # TODO: Description
            };

            interval = mkOption {
              type = types.ints.positive;
              default = 300;
              description = ""; # TODO Describe
            };
          };
        };
      };
    };
  };

  config =
    let
      cfg = config.programs.pimsync;
      applyDefaults =
        _: acc:
        let
          # Select values that could be set in programs.pimsync.defaults and aren't null
          specifiedValues = lib.filterAttrs (n: v: (v != null && cfg.defaults ? n)) acc.pimsync;

          defaults = {
            inherit (acc.remote) userName url;
            password = lib.singleton "cmd" ++ acc.remote.passwordCommand;
          };

          finalPimsync = {
            pimsync = acc.pimsync // cfg.defaults // defaults // specifiedValues;
          };
        in
        acc // finalPimsync;
      calendarAccounts = lib.filterAttrs (_: v: v.pimsync.enable) (
        lib.mapAttrs applyDefaults config.accounts.calendar.accounts
      );
      contactAccounts = lib.filterAttrs (_: v: v.pimsync.enable) (
        lib.mapAttrs applyDefaults config.accounts.contact.accounts
      );

      # Convert a non-nesting attribute set to a list of directives including
      # handling pimsyncs "dynamic parameters"
      attrsToDirectives = lib.mapAttrsToList (
        name: value:
        {
          inherit name;
        }
        // (
          if builtins.typeOf value == "list" then
            {
              children = lib.singleton {
                name = lib.head value;
                params = lib.drop 1 value;
              };
            }
          else
            { params = lib.singleton value; }
        )
      );

      localStorage = calendar: name: acc: {
        name = "storage";
        params = [ "${name}-local" ];
        children =
          (attrsToDirectives {
            inherit (acc.local) path;
            inherit (acc.pimsync) interval;
            fileext = acc.local.fileExt;
            type = if calendar then "vdir/icalendar" else "vdir/vcard";
          })
          ++ (lib.optional acc.pimsync.localReadOnly { name = "readonly"; });
      };

      remoteStorage = calendar: name: acc: {
        name = "storage";
        params = [ "${name}-remote" ];
        children =
          (attrsToDirectives {
            inherit (acc.pimsync) interval url password;
            username = acc.pimsync.userName;
            collection_id = acc.pimsync.collectionId;
            user_agent = acc.pimsync.userAgent;
            type =
              if !calendar then
                "carddav"
              else if acc.remote.type == "caldav" then
                acc.remote.type
              else
                "webcal";
          })
          ++ (lib.optional acc.pimsync.remoteReadOnly { name = "readonly"; });
      };

      getCollections =
        acc:
        let
          inherit (acc.pimsync) collection;
        in
        if builtins.typeOf collection == "string" then
          let
            names = {
              all = lib.singleton "all";
              fromLocal = [
                "from"
                "a"
              ];
              fromRemote = [
                "from"
                "b"
              ];
            };
          in
          lib.singleton {
            name = "collections";
            params = names.${collection};
          }
        else
          map (
            col:
            if builtins.typeOf col == "string" then
              {
                name = "collection";
                params = lib.singleton col;
              }
            else
              {
                name = "collection";
                children = attrsToDirectives col;
              }
          ) collection;

      pair = name: acc: {
        name = "pair";
        params = lib.singleton name;
        children =
          (attrsToDirectives {
            storage_a = "${name}-local";
            storage_b = "${name}-remote";
            on_empty = acc.pimsync.onEmpty;
            on_delete = acc.pimsync.onDelete;
          })
          # Needs to be separate, because this could be a list that's not a dynamic parameter
          ++ (lib.singleton {
            name = "conflict_resolution";
            params =
              let
                cr = acc.pimsync.conflictResolution;
              in
              if cr == "keepLocal" then
                [
                  "keep"
                  "a"
                ]
              else if cr == "keepRemote" then
                [
                  "keep"
                  "b"
                ]
              else if cr == null then
                [ null ]
              else
                cr;
          })
          ++ (getCollections acc);
      };

      multiMapAttrsToList = attrs: lib.concatMap (f: lib.mapAttrsToList f attrs);

      globalConfig = lib.singleton {
        name = "status_path";
        params = lib.singleton cfg.statusPath;
      };

      calendarConfig = multiMapAttrsToList calendarAccounts [
        (localStorage true)
        (remoteStorage true)
        pair
      ];

      contactConfig = multiMapAttrsToList contactAccounts [
        (localStorage false)
        (remoteStorage false)
        pair
      ];

      finalConfig = globalConfig ++ calendarConfig ++ contactConfig;
    in
    lib.mkIf cfg.enable {
      assertions =
        let
          contactRemotes = lib.mapAttrsToList (_: acc: {
            assertion = acc.remote.type == "carddav";
            message = "pimsync can only handle contact remotes of type carddav";
          }) contactAccounts;
          calendarRemotes = lib.mapAttrsToList (_: acc: {
            assertion = acc.remote.type == "caldav" || acc.remote.type == "http";
            message = "pimsync can only handle calendar remotes of types http or caldav";
          }) calendarAccounts;
          idIffHttp = lib.mapAttrsToList (_: acc: [
            {
              assertion = (acc.remote.type == "http") -> (acc.pimsync.collectionId != null);
              message = ''
                You need to manually set a collectionId for pimsync calendars with http type,
                          see https://pimsync.whynothugo.nl/pimsync.conf.5.html#COLLECTION_ID'';
            }
            {
              assertion = (acc.pimsync.collectionId != null) -> (acc.remote.type == "http");
              message = ''
                You only need to set collectionId for calendars with http type.
              '';
            }
          ]) calendarAccounts;
          sharedAsserts = lib.mapAttrsToList (
            _: acc: [
              {
                assertion = acc.local.type == "filesystem";
                message = "pimsync only supports type filesystem for local";
              }
            ]
          );
        in
        lib.flatten [
          contactRemotes
          calendarRemotes
          idIffHttp
          (sharedAsserts contactAccounts)
          (sharedAsserts calendarAccounts)
        ];

      home.packages = [ cfg.package ];

      xdg.configFile."pimsync/pimsync.conf".text = lib.hm.generators.toSCFG { } finalConfig;
    };
}
