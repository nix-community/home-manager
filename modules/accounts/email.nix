{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.accounts.email;

  gpgModule = types.submodule {
    options = {
      key = mkOption {
        type = types.str;
        description = ''
          The key to use as listed in <command>gpg --list-keys</command>.
        '';
      };

      signByDefault = mkOption {
        type = types.bool;
        default = false;
        description = "Sign messages by default.";
      };

      encryptByDefault = mkOption {
        type = types.bool;
        default = false;
        description = "Encrypt outgoing messages by default.";
      };
    };
  };

  signatureModule = types.submodule {
    options = {
      text = mkOption {
        type = types.str;
        default = "";
        example = ''
          --
          Luke Skywalker
          May the force be with you.
        '';
        description = ''
          Signature content.
        '';
      };

      showSignature = mkOption {
        type = types.enum [ "append" "attach" "none" ];
        default = "none";
        description = "Method to communicate the signature.";
      };
    };
  };

  tlsModule = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Whether to enable TLS/SSL.
        '';
      };

      useStartTls = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to use STARTTLS.
        '';
      };

      certificatesFile = mkOption {
        type = types.path;
        default = config.accounts.email.certificatesFile;
        defaultText = "config.accounts.email.certificatesFile";
        description = ''
          Path to file containing certificate authorities that should
          be used to validate the connection authenticity. If
          <literal>null</literal> then the system default is used.
          Note, if set then the system default may still be accepted.
        '';
      };
    };
  };

  imapModule = types.submodule {
    options = {
      host = mkOption {
        type = types.str;
        example = "imap.example.org";
        description = ''
          Hostname of IMAP server.
        '';
      };

      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        example = 993;
        description = ''
          The port on which the IMAP server listens. If
          <literal>null</literal> then the default port is used.
        '';
      };

      tls = mkOption {
        type = tlsModule;
        default = {};
        description = ''
          Configuration for secure connections.
        '';
      };
    };
  };

  smtpModule = types.submodule {
    options = {
      host = mkOption {
        type = types.str;
        example = "smtp.example.org";
        description = ''
          Hostname of SMTP server.
        '';
      };

      port = mkOption {
        type = types.nullOr types.port;
        default = null;
        example = 465;
        description = ''
          The port on which the SMTP server listens. If
          <literal>null</literal> then the default port is used.
        '';
      };

      tls = mkOption {
        type = tlsModule;
        default = {};
        description = ''
          Configuration for secure connections.
        '';
      };
    };
  };

  maildirModule = types.submodule ({ config, ... }: {
    options = {
      path = mkOption {
        type = types.str;
        description = ''
          Path to maildir directory where mail for this account is
          stored. This is relative to the base maildir path.
        '';
      };

      absPath = mkOption {
        type = types.path;
        readOnly = true;
        internal = true;
        default = "${cfg.maildirBasePath}/${config.path}";
        description = ''
          A convenience option whose value is the absolute path of
          this maildir.
        '';
      };
    };
  });

  mailAccountOpts = { name, config, ... }: {
    options = {
      name = mkOption {
        type = types.str;
        readOnly = true;
        description = ''
          Unique identifier of the account. This is set to the
          attribute name of the account configuration.
        '';
      };

      primary = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether this is the primary account. Only one account may be
          set as primary.
        '';
      };

      flavor = mkOption {
        type = types.enum [ "plain" "gmail.com" "runbox.com" ];
        default = "plain";
        description = ''
          Some email providers have peculiar behavior that require
          special treatment. This option is therefore intended to
          indicate the nature of the provider.
          </para><para>
          When this indicates a specific provider then, for example,
          the IMAP and SMTP server configuration may be set
          automatically.
        '';
      };

      address = mkOption {
        type = types.strMatching ".*@.*";
        example = "jane.doe@example.org";
        description = "The email address of this account.";
      };

      aliases = mkOption {
        type = types.listOf (types.strMatching ".*@.*");
        default = [];
        example = [ "webmaster@example.org" "admin@example.org" ];
        description = "Alternative email addresses of this account.";
      };

      realName = mkOption {
        type = types.str;
        example = "Jane Doe";
        description = "Name displayed when sending mails.";
      };

      userName = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          The server username of this account. This will be used as
          the SMTP and IMAP user name.
        '';
      };

      passwordCommand = mkOption {
        type = types.nullOr (types.either types.str (types.listOf types.str));
        default = null;
        apply = p: if isString p then splitString " " p else p;
        example = "secret-tool lookup email me@example.org";
        description = ''
          A command, which when run writes the account password on
          standard output.
        '';
      };

      folders = mkOption {
        type = types.submodule {
          options = {
            inbox = mkOption {
              type = types.str;
              default = "Inbox";
              description = ''
                Relative path of the inbox mail.
              '';
            };

            sent = mkOption {
              type = types.nullOr types.str;
              default = "Sent";
              description = ''
                Relative path of the sent mail folder.
              '';
            };

            drafts = mkOption {
              type = types.str;
              default = "Drafts";
              description = ''
                Relative path of the drafts mail folder.
              '';
            };

            trash = mkOption {
              type = types.str;
              default = "Trash";
              description = ''
                Relative path of the deleted mail folder.
              '';
            };
          };
        };
        default = {};
        description = ''
          Standard email folders.
        '';
      };

      imap = mkOption {
        type = types.nullOr imapModule;
        default = null;
        description = ''
          The IMAP configuration to use for this account.
        '';
      };

      signature = mkOption {
        type = signatureModule;
        default = {};
        description = ''
          Signature configuration.
        '';
      };

      gpg = mkOption {
        type = types.nullOr gpgModule;
        default = null;
        description = ''
          GPG configuration.
        '';
      };

      smtp = mkOption {
        type = types.nullOr smtpModule;
        default = null;
        description = ''
          The SMTP configuration to use for this account.
        '';
      };

      maildir = mkOption {
        type = types.nullOr maildirModule;
        defaultText = { path = "\${name}"; };
        description = ''
          Maildir configuration for this account.
        '';
      };
    };

    config = mkMerge [
      {
        name = name;
        maildir = mkOptionDefault { path = "${name}"; };
      }

      (mkIf (config.flavor == "gmail.com") {
        userName = mkDefault config.address;

        imap = {
          host = "imap.gmail.com";
        };

        smtp = {
          host = "smtp.gmail.com";
          port = if config.smtp.tls.useStartTls then 587 else 465;
        };
      })

      (mkIf (config.flavor == "runbox.com") {
        imap = {
          host = "mail.runbox.com";
        };

        smtp = {
          host = "mail.runbox.com";
        };
      })
    ];
  };

in

{
  options.accounts.email = {
    certificatesFile = mkOption {
      type = types.path;
      default = "/etc/ssl/certs/ca-certificates.crt";
      description = ''
        Path to default file containing certificate authorities that
        should be used to validate the connection authenticity. This
        path may be overridden on a per-account basis.
      '';
    };

    maildirBasePath = mkOption {
      type = types.str;
      default = "${config.home.homeDirectory}/Maildir";
      defaultText = "$HOME/Maildir";
      apply = p:
        if hasPrefix "/" p
        then p
        else "${config.home.homeDirectory}/${p}";
      description = ''
        The base directory for account maildir directories. May be a
        relative path, in which case it is relative the home
        directory.
      '';
    };

    accounts = mkOption {
      type = types.attrsOf (types.submodule [
        mailAccountOpts
        (import ../programs/alot-accounts.nix pkgs)
        (import ../programs/astroid-accounts.nix)
        (import ../programs/getmail-accounts.nix)
        (import ../programs/mbsync-accounts.nix)
        (import ../programs/msmtp-accounts.nix)
        (import ../programs/notmuch-accounts.nix)
        (import ../programs/offlineimap-accounts.nix)
      ]);
      default = {};
      description = "List of email accounts.";
    };
  };

  config = mkIf (cfg.accounts != {}) {
    assertions = [
      (
        let
          primaries =
            catAttrs "name"
            (filter (a: a.primary)
            (attrValues cfg.accounts));
        in
          {
            assertion = length primaries == 1;
            message =
              "Must have exactly one primary mail account but found "
              + toString (length primaries)
              + optionalString (length primaries > 1)
                  (", namely " + concatStringsSep ", " primaries);
          }
      )
    ];
  };
}
