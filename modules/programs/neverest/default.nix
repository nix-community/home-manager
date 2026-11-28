{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.neverest;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = [ lib.maintainers.philocalyst ];

  options = {
    programs.neverest = {
      enable = lib.mkEnableOption "synchronization using Neverest";
      package = lib.mkPackageOption pkgs "neverest" { };
    };

    accounts.email.accounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule (import ./accounts.nix));
    };
  };

  config = lib.mkIf cfg.enable (
    let
      enabledAccounts = lib.filterAttrs (
        _: a: a.enable && a.neverest.enable
      ) config.accounts.email.accounts;

      useXdg = !pkgs.stdenv.hostPlatform.isDarwin || config.home.preferXdgDirectories;

      # Neverest's real TOML schema (verified against email-lib 0.24.0 /
      # neverest 1.0.0-beta serde structs) is:
      #
      #   [accounts.<name>.folder]
      #   filters = "all" | { include = [...] } | { exclude = [...] }
      #
      #   [accounts.<name>.left.backend]
      #   type = "maildir"
      #   root-dir = "..."
      #
      #   [accounts.<name>.right.backend]
      #   type = "imap"
      #   host = "..."
      #   port = 993
      #   encryption = "tls" | "start-tls" | "none"
      #   login = "..."
      #   [accounts.<name>.right.backend.passwd]
      #   command = "shell command string"   # run via `sh -c`, NOT an argv list
      #
      #   [accounts.<name>.right.folder.permissions]
      #   create = false
      #   delete = false
      #   [accounts.<name>.right.message.permissions]
      #   create = false
      #   delete = false
      #
      # There is no `pool-size`, `mailbox`, or `sasl.plain` key anywhere in
      # the schema (Config/AccountConfig both use `deny_unknown_fields`, so
      # any account-level field outside `default`/`folder`/`envelope`/`left`/
      # `right` is a hard parse error, not silently ignored).
      generatedConfig = tomlFormat.generate "config.toml" {
        accounts = builtins.mapAttrs (
          _: acc:
          let
            nv = acc.neverest;
            tls = acc.imap.tls.enable;
            port =
              if acc.imap.port != null then
                acc.imap.port
              else if tls then
                993
              else
                143;

            encryption =
              if !tls then
                "none"
              else if acc.imap.tls.useStartTls then
                "start-tls"
              else
                "tls";

            filters = nv.mailboxFilters;
            folderFilters =
              if filters == null then
                null
              else if filters.include != [ ] then
                { inherit (filters) include; }
              else if filters.exclude != [ ] then
                { inherit (filters) exclude; }
              else
                null;

            baseConfig = {
              left.backend = {
                type = "maildir";
                "root-dir" = acc.maildir.absPath;
              };
              right.backend = {
                type = "imap";
                host = acc.imap.host;
                inherit port encryption;
                login = acc.userName;
                # neverest's `passwd.command` is a single shell command line
                # (executed via `sh -c`), not an argv array, so the
                # word-split list from `accounts.email`'s passwordCommand
                # must be re-quoted into one shell-safe string.
                passwd.command = lib.escapeShellArgs acc.passwordCommand;
              };
            };
          in
          builtins.foldl' lib.recursiveUpdate baseConfig [
            (lib.optionalAttrs (folderFilters != null) { folder.filters = folderFilters; })
            (lib.optionalAttrs nv.protectServer {
              right.folder.permissions = {
                create = false;
                delete = false;
              };
              right.message.permissions = {
                create = false;
                delete = false;
              };
            })
            nv.extraConfig
          ]
        ) enabledAccounts;
      };
    in
    {
      assertions =
        let
          check =
            cond: msg:
            let
              bad = builtins.attrNames (lib.filterAttrs (_: cond) enabledAccounts);
            in
            {
              assertion = bad == [ ];
              message = "neverest: ${msg}: ${builtins.concatStringsSep ", " bad}";
            };
        in
        [
          (check (a: a.maildir == null) "missing maildir configuration")
          (check (a: a.imap == null) "missing IMAP configuration")
          (check (a: a.passwordCommand == null) "missing passwordCommand")
          (check (a: a.userName == null) "missing userName")
          (check (
            a:
            let
              f = a.neverest.mailboxFilters or { };
            in
            (f.include or [ ]) != [ ] && (f.exclude or [ ]) != [ ]
          ) "mailboxFilters.include and exclude are mutually exclusive")
        ];

      home.packages = [ cfg.package ];

      xdg.configFile."neverest/config.toml" = lib.mkIf useXdg {
        source = generatedConfig;
      };

      home.file."Library/Application Support/neverest/config.toml" = lib.mkIf (!useXdg) {
        source = generatedConfig;
      };

      home.activation = lib.mkIf (enabledAccounts != { }) {
        createNeverestMaildir = lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
          $DRY_RUN_CMD mkdir -m700 -p $VERBOSE_ARG ${
            builtins.concatStringsSep " " (
              map (a: lib.escapeShellArg a.maildir.absPath) (builtins.attrValues enabledAccounts)
            )
          }
        '';
      };
    }
  );
}
