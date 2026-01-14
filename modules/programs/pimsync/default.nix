{
  config,
  lib,
  pkgs,
  ...
}:
{
  options = {
    programs.pimsync = {
      enable = lib.mkEnableOption "pimsync";

      package = lib.mkPackageOption pkgs "pimsync" { };

      settings = lib.mkOption {
        description = ''
          Settings to be added to pimsync.conf.
          See {manpage}`pimsync.conf(5)`.
        '';
        type = lib.hm.types.SCFGDirectives;
        default = [
          {
            name = "status_path";
            params = [ "${config.xdg.dataHome}/pimsync/status" ];
          }
        ];
        defaultText = lib.literalExpression ''
          [
            {
              name = "status_path";
              params = [ "''${config.xdg.dataHome}/pimsync/status" ];
            }
          ]
        '';
      };
    };
  };

  config =
    let
      cfg = config.programs.pimsync;
      calendarAccounts = lib.filterAttrs (_: v: v.pimsync.enable) config.accounts.calendar.accounts;
      contactAccounts = lib.filterAttrs (_: v: v.pimsync.enable) config.accounts.contact.accounts;

      # Provides a very naïve translation of an (non-nested) attribute set to a SCFGDirective
      attrsToDirectives = lib.mapAttrsToList (
        name: value: {
          inherit name;
          params = lib.toList value;
        }
      );

      localStorage = calendar: name: acc: {
        name = "storage";
        params = [ "${if calendar then "calendar" else "contacts"}-${name}-local" ];
        children =
          (attrsToDirectives {
            inherit (acc.local) path;
            fileext = acc.local.fileExt;
            type = if calendar then "vdir/icalendar" else "vdir/vcard";
          })
          ++ acc.pimsync.extraLocalStorageDirectives;
      };

      remoteStorage = calendar: name: acc: {
        name = "storage";
        params = [ "${if calendar then "calendar" else "contacts"}-${name}-remote" ];
        children =
          (attrsToDirectives {
            inherit (acc.remote) url;
            username = acc.remote.userName;
            type =
              if !calendar then
                "carddav"
              else if acc.remote.type == "caldav" then
                acc.remote.type
              else
                "webcal";
          })
          ++ lib.optional (acc.remote.passwordCommand != null) {
            name = "password";
            children = lib.singleton {
              name = "cmd";
              params = acc.remote.passwordCommand;
            };
          }
          ++ acc.pimsync.extraRemoteStorageDirectives;
      };

      pair = calendar: name: acc: {
        name = "pair";
        params = lib.singleton "${if calendar then "calendar" else "contacts"}-${name}";
        children =
          (attrsToDirectives {
            storage_a = "${if calendar then "calendar" else "contacts"}-${name}-local";
            storage_b = "${if calendar then "calendar" else "contacts"}-${name}-remote";
          })
          ++ acc.pimsync.extraPairDirectives;
      };

      multiMapAttrsToList = calendar: attrs: lib.concatMap (f: lib.mapAttrsToList (f calendar) attrs);

      calendarConfig = multiMapAttrsToList true calendarAccounts [
        localStorage
        remoteStorage
        pair
      ];

      contactConfig = multiMapAttrsToList false contactAccounts [
        localStorage
        remoteStorage
        pair
      ];

      accountSettings = calendarConfig ++ contactConfig;

      localStorageDir = name: acc: lib.attrsets.getAttrFromPath [ "local" "path" ] acc;

      calendarLocalStorageDirs = lib.mapAttrsToList localStorageDir calendarAccounts;
      contactLocalStorageDirs = lib.mapAttrsToList localStorageDir contactAccounts;
      localStorageDirs = calendarLocalStorageDirs ++ contactLocalStorageDirs;

      mkTmpFileRule = (dir: "d ${dir} 0750 ${config.home.username} users - -");
      tmpFileRules = map mkTmpFileRule localStorageDirs;
    in
    lib.mkIf cfg.enable {
      meta.maintainers = [ lib.maintainers.antonmosich ];

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
          (sharedAsserts contactAccounts)
          (sharedAsserts calendarAccounts)
        ];

      home.packages = [ cfg.package ];

      systemd.user.tmpfiles.rules = lib.optionals pkgs.stdenv.hostPlatform.isLinux tmpFileRules;

      home.activation.createDavDirectories = lib.mkIf (!pkgs.stdenv.hostPlatform.isLinux) (
        let
          directoriesList = localStorageDirs;
          mkdir = (dir: ''[[ -L "${dir}" ]] || run mkdir -p $VERBOSE_ARG "${dir}"'');
        in
        lib.hm.dag.entryAfter [ "linkGeneration" ] (
          lib.strings.concatMapStringsSep "\n" mkdir directoriesList
        )
      );

      xdg.configFile."pimsync/pimsync.conf".text = lib.hm.generators.toSCFG { } (
        accountSettings ++ cfg.settings
      );
    };
}
