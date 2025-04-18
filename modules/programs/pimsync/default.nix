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
        acc:
        let
          # Select values that can't be set in programs.pimsync.defaults or are null
          pimsyncValues = lib.filterAttrs (n: v: !(v == null && cfg.defaults ? n)) acc.pimsync;
          finalPimsync = {
            pimsync = cfg.defaults // pimsyncValues;
          };
        in
        acc // finalPimsync;
      calendarAccounts = lib.filterAttrs (_: v: v.pimsync.enable) (
        lib.mapAttrs applyDefaults config.accounts.calendar.accounts
      );
      contactAccounts = lib.filterAttrs (_: v: v.pimsync.enable) (
        lib.mapAttrs applyDefaults config.accounts.contact.accounts
      );

      localStorage = acc: "";
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
    };
}
