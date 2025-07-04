{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption optionalAttrs types;

  # aliases
  inherit (config.programs) himalaya;
  tomlFormat = pkgs.formats.toml { };

  # attrs util that removes entries containing a null value
  compactAttrs = lib.filterAttrs (_: val: !isNull val);

  # Needed for notmuch config, because the DB is here, and not in each
  # account's dir
  maildirBasePath = config.accounts.email.maildirBasePath;

  # make encryption config based on the given home-manager email
  # account TLS config
  mkEncryptionConfig =
    tls:
    if tls.useStartTls then
      "start-tls"
    else if tls.enable then
      "tls"
    else
      "none";

  # make a himalaya account config based on the given home-manager
  # email account config
  mkAccountConfig =
    _: account:
    let
      notmuchEnabled = account.notmuch.enable;
      imapEnabled = !isNull account.imap && !notmuchEnabled;
      maildirEnabled = !isNull account.maildir && !imapEnabled && !notmuchEnabled;

      globalConfig = {
        email = account.address;
        display-name = account.realName;
        default = account.primary;
        folder.aliases = {
          inbox = account.folders.inbox;
          sent = account.folders.sent;
          drafts = account.folders.drafts;
          trash = account.folders.trash;
        };
      };

      signatureConfig = optionalAttrs (account.signature.showSignature == "append") {
        # TODO: signature cannot be attached yet
        # https://github.com/pimalaya/himalaya/issues/534
        signature = account.signature.text;
        signature-delim = account.signature.delimiter;
      };

      imapConfig = optionalAttrs imapEnabled (compactAttrs {
        backend.type = "imap";
        backend.host = account.imap.host;
        backend.port = account.imap.port;
        backend.encryption.type = mkEncryptionConfig account.imap.tls;
        backend.login = account.userName;
        backend.auth.type = "password";
        backend.auth.cmd = builtins.concatStringsSep " " account.passwordCommand;
      });

      maildirConfig = optionalAttrs maildirEnabled (compactAttrs {
        backend.type = "maildir";
        backend.root-dir = account.maildir.absPath;
      });

      notmuchConfig = optionalAttrs notmuchEnabled (compactAttrs {
        backend.type = "notmuch";
        backend.db-path = maildirBasePath;
      });

      smtpConfig = optionalAttrs (!isNull account.smtp) (compactAttrs {
        message.send.backend.type = "smtp";
        message.send.backend.host = account.smtp.host;
        message.send.backend.port = account.smtp.port;
        message.send.backend.encryption.type = mkEncryptionConfig account.smtp.tls;
        message.send.backend.login = account.userName;
        message.send.backend.auth.type = "password";
        message.send.backend.auth.cmd = builtins.concatStringsSep " " account.passwordCommand;
      });

      sendmailConfig = optionalAttrs (isNull account.smtp && !isNull account.msmtp) {
        message.send.backend.type = "sendmail";
        message.send.backend.cmd = lib.getExe pkgs.msmtp;
      };

      config = lib.attrsets.mergeAttrsList [
        globalConfig
        signatureConfig
        imapConfig
        maildirConfig
        notmuchConfig
        smtpConfig
        sendmailConfig
      ];

    in
    lib.recursiveUpdate config account.himalaya.settings;

in
{
  meta.maintainers = with lib.maintainers; [
    soywod
    toastal
  ];

  imports = [
    (lib.mkRemovedOptionModule [ "services" "himalaya-watch" "enable" ] ''
      services.himalaya-watch has been removed.

      The watch feature moved away from Himalaya scope, and resides
      now in its own project called Mirador. Once the v1 released, the
      service will land back in nixpkgs and home-manager.

      See <https://github.com/pimalaya/mirador>.
    '')
  ];

  options = {
    programs.himalaya = {
      enable = lib.mkEnableOption "the email client Himalaya CLI";
      package = lib.mkPackageOption pkgs "himalaya" { nullable = true; };
      settings = mkOption {
        type = types.submodule { freeformType = tomlFormat.type; };
        default = { };
        description = ''
          Himalaya CLI global configuration.
          See <https://github.com/pimalaya/himalaya/blob/master/config.sample.toml> for supported values.
        '';
      };
    };

    accounts.email.accounts = mkOption {
      type = types.attrsOf (
        types.submodule {
          options.himalaya = {
            enable = lib.mkEnableOption "the email client Himalaya CLI for this email account";

            settings = mkOption {
              type = types.submodule { freeformType = tomlFormat.type; };
              default = { };
              description = ''
                Himalaya CLI configuration for this email account.
                See <https://github.com/pimalaya/himalaya/blob/master/config.sample.toml> for supported values.
              '';
            };
          };
        }
      );
    };
  };

  config = lib.mkIf himalaya.enable {
    home.packages = lib.mkIf (himalaya.package != null) [ himalaya.package ];

    xdg = {
      configFile."himalaya/config.toml".source =
        let
          enabledAccounts = lib.filterAttrs (
            _: account: account.himalaya.enable
          ) config.accounts.email.accounts;
          accountsConfig = lib.mapAttrs mkAccountConfig enabledAccounts;
          globalConfig = compactAttrs himalaya.settings;
          allConfig = globalConfig // {
            accounts = accountsConfig;
          };
        in
        tomlFormat.generate "himalaya.config.toml" allConfig;

      desktopEntries.himalaya =
        lib.mkIf (pkgs.stdenv.hostPlatform.isLinux && (himalaya.package != null))
          {
            type = "Application";
            name = "himalaya";
            genericName = "Email Client";
            comment = "CLI to manage emails";
            terminal = true;
            exec = "himalaya %u";
            categories = [ "Network" ];
            mimeType = [
              "x-scheme-handler/mailto"
              "message/rfc822"
            ];
            settings = {
              Keywords = "email";
            };
          };
    };
  };
}
