{ config, lib, pkgs, ... }:

with lib;

let

  dag = config.lib.dag;

  cfg = config.programs.mbsync;

  # Accounts for which mbsync is enabled.
  mbsyncAccounts =
    filter (a: a.mbsync.enable) (attrValues config.accounts.email.accounts);

  genTlsConfig = tls: {
      SSLType =
        if !tls.enable          then "None"
        else if tls.useStartTls then "STARTTLS"
        else                         "IMAPS";
    }
    //
    optionalAttrs (tls.enable && tls.certificatesFile != null) {
      CertificateFile = tls.certificatesFile;
    };

  masterSlaveMapping = {
    none = "None";
    imap = "Master";
    maildir = "Slave";
    both = "Both";
  };

  genSection = header: entries:
    let
      escapeValue = escape [ "\"" ];
      genValue = v:
        if isList v
        then concatMapStringsSep " " genValue v
        else "\"${escapeValue v}\"";
    in
      ''
        ${header}
        ${concatStringsSep "\n"
          (mapAttrsToList (n: v: "${n} ${genValue v}") entries)}
      '';

  genAccountConfig = account: with account;
    if (imap == null || maildir == null)
    then ""
    else
      genSection "IMAPAccount ${name}" (
        {
          Host = imap.host;
          User = userName;
          PassCmd = toString passwordCommand;
        }
        //
        genTlsConfig imap.tls
        //
        optionalAttrs (imap.port != null) { Port = toString imap.port; }
      )
      + "\n"
      + genSection "IMAPStore ${name}-remote" {
        Account = name;
      }
      + "\n"
      + genSection "MaildirStore ${name}-local" (
        {
          Path = "${maildir.absPath}/";
          Inbox = "${maildir.absPath}/${folders.inbox}";
          SubFolders = "Verbatim";
        }
        //
        optionalAttrs (mbsync.flatten != null) { Flatten = mbsync.flatten; }
      )
      + "\n"
      + genSection "Channel ${name}" {
        Master = ":${name}-remote:";
        Slave = ":${name}-local:";
        Patterns = mbsync.patterns;
        Create = masterSlaveMapping.${mbsync.create};
        Remove = masterSlaveMapping.${mbsync.remove};
        Expunge = masterSlaveMapping.${mbsync.expunge};
        SyncState = "*";
      }
      + "\n";

  genGroupConfig = name: channels:
    let
      genGroupChannel = n: boxes: "Channel ${n}:${concatStringsSep "," boxes}";
    in
      concatStringsSep "\n" (
        [ "Group ${name}" ] ++ mapAttrsToList genGroupChannel channels
      );

in

{
  options = {
    programs.mbsync = {
      enable = mkEnableOption "mbsync IMAP4 and Maildir mailbox synchronizer";

      package = mkOption {
        type = types.package;
        default = pkgs.isync;
        defaultText = "pkgs.isync";
        example = literalExample "pkgs.isync";
        description = "The package to use for the mbsync binary.";
      };

      groups = mkOption {
        type = types.attrsOf (types.attrsOf (types.listOf types.str));
        default = {};
        example = literalExample ''
          {
            inboxes = {
              account1 = [ "Inbox" ];
              account2 = [ "Inbox" ];
            };
          }
        '';
        description = ''
          Definition of groups.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra configuration lines to add to the mbsync configuration.
        '';
      };
    };

    accounts.email.accounts = mkOption {
      options = [
        {
          mbsync = {
            enable = mkEnableOption "synchronization using mbsync";

            flatten = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = ".";
              description = ''
                If set, flattens the hierarchy within the maildir by
                substituting the canonical hierarchy delimiter
                <literal>/</literal> with this value.
              '';
            };

            create = mkOption {
              type = types.enum [ "none" "maildir" "imap" "both" ];
              default = "none";
              example = "maildir";
              description = ''
                Automatically create missing mailboxes within the
                given mail store.
              '';
            };

            remove = mkOption {
              type = types.enum [ "none" "maildir" "imap" "both" ];
              default = "none";
              example = "imap";
              description = ''
                Propagate mailbox deletions to the given mail store.
              '';
            };

            expunge = mkOption {
              type = types.enum [ "none" "maildir" "imap" "both" ];
              default = "none";
              example = "both";
              description = ''
                Permanently remove messages marked for deletion from
                the given mail store.
              '';
            };

            patterns = mkOption {
              type = types.listOf types.str;
              default = [ "*" ];
              description = ''
                Pattern of mailboxes to synchronize.
              '';
            };
          };
        }
      ];
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (
        let
          badAccounts = filter (a: a.maildir == null) mbsyncAccounts;
        in
          {
            assertion = badAccounts == [];
            message = "mbsync: Missing maildir configuration for accounts: "
              + concatMapStringsSep ", " (a: a.name) badAccounts;
          }
      )

      (
        let
          badAccounts = filter (a: a.imap == null) mbsyncAccounts;
        in
          {
            assertion = badAccounts == [];
            message = "mbsync: Missing IMAP configuration for accounts: "
              + concatMapStringsSep ", " (a: a.name) badAccounts;
          }
      )
    ];

    home.packages = [ cfg.package ];

    home.file.".mbsyncrc".text =
      let
        accountsConfig = map genAccountConfig mbsyncAccounts;
        groupsConfig = mapAttrsToList genGroupConfig cfg.groups;
      in
        concatStringsSep "\n" (
          [ "# Generated by Home Manager.\n" ]
          ++ accountsConfig
          ++ groupsConfig
          ++ optional (cfg.extraConfig != "") cfg.extraConfig
        );

    home.activation.createMaildir =
      dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ] ''
        $DRY_RUN_CMD mkdir -m700 -p $VERBOSE_ARG ${
          concatMapStringsSep " " (a: a.maildir.absPath) mbsyncAccounts
        }
      '';
  };
}
