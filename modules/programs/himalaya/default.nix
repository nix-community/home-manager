{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.programs) himalaya;
  inherit (lib)
    attrNames
    concatMap
    concatStringsSep
    elem
    filterAttrs
    maintainers
    mapAttrs
    mapAttrsToList
    mergeAttrsList
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    optional
    optionalAttrs
    recursiveUpdate
    types
    ;

  tomlFormat = pkgs.formats.toml { };
  compactAttrs = filterAttrs (_: val: !isNull val);

  enabledAccounts = filterAttrs (
    _: account: account.enable && account.himalaya.enable
  ) config.accounts.email.accounts;

  sasl = {
    anonymous = null;
    login = "password";
    oauthbearer = "token";
    plain = "password";
    "scram-sha-256" = "password";
    xoauth2 = "token";
  };

  supportedSasl = attrNames sasl;

  saslValidator =
    pred:
    concatMap
      (
        protocol:
        mapAttrsToList (name: _: "${name}.${protocol}") (
          filterAttrs (_: account: !isNull account.${protocol} && pred protocol account) enabledAccounts
        )
      )
      [
        "imap"
        "smtp"
      ];

  unsupportedSasl = saslValidator (
    protocol: account:
    !isNull account.${protocol}.authentication && !elem account.${protocol}.authentication supportedSasl
  );

  unnamedSasl = saslValidator (
    protocol: account: isNull account.${protocol}.authentication && !isNull account.passwordCommand
  );

  mkTlsConfig =
    protocol: account:
    let
      transport = account.${protocol};
      starttls = transport.tls.enable && transport.tls.useStartTls;
      scheme = if transport.tls.enable && !starttls then "${protocol}s" else protocol;
      authority =
        if isNull transport.port then transport.host else "${transport.host}:${toString transport.port}";
    in
    {
      inherit starttls;
      server = "${scheme}://${authority}";
    };

  mkSaslConfig =
    protocol: account:
    let
      mechanism = account.${protocol}.authentication;
      field = sasl.${mechanism} or null;
      usable = isNull field || !isNull account.passwordCommand;
    in
    optionalAttrs (!isNull mechanism && usable) {
      sasl.${mechanism} = optionalAttrs (!isNull field) {
        username = account.userName;
        ${field}.command = builtins.concatStringsSep " " account.passwordCommand;
      };
    };

  mkAccountConfig =
    _: account:
    let
      imapEnabled = !isNull account.imap;
      jmapEnabled =
        !isNull account.jmap
        && !imapEnabled
        && !(isNull account.jmap.host && isNull account.jmap.sessionUrl);
      maildirEnabled = !isNull account.maildir && !imapEnabled && !jmapEnabled;

      globalConfig = {
        default = account.primary;
        mailbox.alias = compactAttrs {
          inherit (account.folders) inbox;
          inherit (account.folders) sent;
          inherit (account.folders) drafts;
          inherit (account.folders) trash;
        };
      };

      imapConfig = optionalAttrs imapEnabled {
        imap = (mkTlsConfig "imap" account) // mkSaslConfig "imap" account;
      };

      smtpConfig = optionalAttrs (!isNull account.smtp) {
        smtp = (mkTlsConfig "smtp" account) // mkSaslConfig "smtp" account;
      };

      jmapConfig = optionalAttrs jmapEnabled {
        jmap = {
          server = if isNull account.jmap.host then account.jmap.sessionUrl else account.jmap.host;
        }
        // optionalAttrs (!isNull account.passwordCommand) {
          auth.basic = {
            username = account.userName;
            password.command = builtins.concatStringsSep " " account.passwordCommand;
          };
        };
      };

      maildirConfig = optionalAttrs maildirEnabled {
        maildir.root = account.maildir.absPath;
      };

      config = mergeAttrsList [
        globalConfig
        imapConfig
        jmapConfig
        maildirConfig
        smtpConfig
      ];

    in
    recursiveUpdate config account.himalaya.settings;

in
{
  meta.maintainers = with maintainers; [
    soywod
    toastal
  ];

  # composers and readers integration
  imports = [ ./mblaze.nix ];

  options = {
    programs.himalaya = {
      enable = mkEnableOption "Himalaya CLI, the CLI to manage emails";
      package = mkPackageOption pkgs "himalaya" { nullable = true; };
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
      type = types.attrsOf (types.submodule (import ./accounts.nix pkgs));
    };
  };

  config = mkIf himalaya.enable {
    assertions = [
      {
        assertion = unsupportedSasl == [ ];
        message = ''
          Himalaya CLI speaks the ${concatStringsSep ", " supportedSasl} SASL
          mechanisms; these accounts ask for one it does not implement:
          ${concatStringsSep ", " unsupportedSasl}.
        '';
      }
      {
        assertion = unnamedSasl == [ ];
        message = ''
          Himalaya CLI negotiates no SASL mechanism, so an account carrying a
          password command has to name the one to send it with. Set
          accounts.email.accounts.<name>.<protocol>.authentication to one of
          ${concatStringsSep ", " supportedSasl} on:
          ${concatStringsSep ", " unnamedSasl}.
        '';
      }
    ];

    home.packages = optional (!isNull himalaya.package) himalaya.package;

    xdg.configFile = {
      "himalaya/config.toml".source =
        let
          accountsConfig = mapAttrs mkAccountConfig enabledAccounts;
          globalConfig = compactAttrs himalaya.settings;
          allConfig = globalConfig // {
            accounts = accountsConfig;
          };
        in
        tomlFormat.generate "himalaya.config.toml" allConfig;
    };
  };
}
