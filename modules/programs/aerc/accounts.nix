{
  config,
  lib,
  confSections,
  confSection,
  writeText,
  writeShellScript,
  ...
}:
let
  inherit (lib) literalExpression mkOption types;

  mapAttrNames =
    f: attr:
    lib.listToAttrs (
      lib.attrValues (
        lib.mapAttrs (k: v: {
          name = f k;
          value = v;
        }) attr
      )
    );

  addAccountName = name: k: "${k}:account=${name}";

  oauth2Params = mkOption {
    type =
      with types;
      nullOr (submodule {
        options = {
          token_endpoint = mkOption {
            type = nullOr str;
            default = null;
            description = "The OAuth2 token endpoint.";
          };
          client_id = mkOption {
            type = nullOr str;
            default = null;
            description = "The OAuth2 client identifier.";
          };
          client_secret = mkOption {
            type = nullOr str;
            default = null;
            description = "The OAuth2 client secret.";
          };
          scope = mkOption {
            type = nullOr str;
            default = null;
            description = "The OAuth2 requested scope.";
          };
        };
      });
    default = null;
    example = {
      token_endpoint = "<token_endpoint>";
    };
    description = ''
      Sets the oauth2 params if authentication mechanism oauthbearer or
      xoauth2 is used.
      See {manpage}`aerc-imap(5)`.
    '';
  };

in
{
  type = mkOption {
    type = types.attrsOf (
      types.submodule {
        options.aerc = {
          enable = lib.mkEnableOption "aerc";
          extraAccounts = mkOption {
            type = confSection;
            default = { };
            example = literalExpression ''{ source = "maildir://~/Maildir/example"; }'';
            description = ''
              Extra config added to the configuration section for this account in
              {file}`$HOME/.config/aerc/accounts.conf`.
              See {manpage}`aerc-accounts(5)`.
            '';
          };

          extraBinds = mkOption {
            type = confSections;
            default = { };
            example = literalExpression ''{ messages = { d = ":move ''${folder.trash}<Enter>"; }; }'';
            description = ''
              Extra bindings specific to this account, added to
              {file}`$HOME/.config/aerc/binds.conf`.
              See {manpage}`aerc-binds(5)`.
            '';
          };

          extraConfig = mkOption {
            type = confSections;
            default = { };
            example = literalExpression "{ ui = { sidebar-width = 25; }; }";
            description = ''
              Config specific to this account, added to {file}`$HOME/.config/aerc/aerc.conf`.
              Aerc only supports per-account UI configuration.
              For other sections of {file}`$HOME/.config/aerc/aerc.conf`,
              use `programs.aerc.extraConfig`.
              See {manpage}`aerc-config(5)`.
            '';
          };

          imapAuth = mkOption {
            type =
              with types;
              nullOr (enum [
                "oauthbearer"
                "xoauth2"
              ]);
            default = null;
            example = "auth";
            description = ''
              Sets the authentication mechanism if imap is used as the incoming
              method.
              See {manpage}`aerc-imap(5)`.
            '';
          };

          imapOauth2Params = oauth2Params;

          smtpAuth = mkOption {
            type =
              with types;
              nullOr (enum [
                "none"
                "plain"
                "login"
                "oauthbearer"
                "xoauth2"
              ]);
            default = "plain";
            example = "auth";
            description = ''
              Sets the authentication mechanism if smtp is used as the outgoing
              method.
              See {manpage}`aerc-smtp(5)`.
            '';
          };

          smtpOauth2Params = oauth2Params;
        };
      }
    );
  };

  mkAccount =
    name: account:
    let
      nullOrMap = f: v: if v == null then v else f v;

      optPort = port: if port != null then ":${toString port}" else "";

      optAttr = k: v: if v != null && v != [ ] && v != "" then { ${k} = v; } else { };

      optPwCmd = k: p: optAttr "${k}-cred-cmd" (nullOrMap (lib.concatStringsSep " ") p);

      useOauth =
        auth:
        builtins.elem auth [
          "oauthbearer"
          "xoauth2"
        ];

      oauthParams =
        { auth, params }:
        if useOauth auth && params != null && params != { } then
          "?"
          + builtins.concatStringsSep "&" (
            lib.attrsets.mapAttrsToList (k: v: k + "=" + lib.strings.escapeURL v) (
              lib.attrsets.filterAttrs (k: v: v != null) params
            )
          )
        else
          "";

      mkConfig = {
        maildir = cfg: {
          source = "maildir://${config.accounts.email.maildirBasePath}/${cfg.maildir.path}";
        };

        maildirpp = cfg: {
          source = "maildirpp://${config.accounts.email.maildirBasePath}/${cfg.maildir.path}/Inbox";
        };

        imap =
          {
            userName,
            imap,
            passwordCommand,
            aerc,
            ...
          }@cfg:
          let
            loginMethod' = if cfg.aerc.imapAuth != null then "+${cfg.aerc.imapAuth}" else "";

            oauthParams' = oauthParams {
              auth = cfg.aerc.imapAuth;
              params = cfg.aerc.imapOauth2Params;
            };

            protocol =
              if imap.tls.enable then
                if imap.tls.useStartTls then "imap" else "imaps${loginMethod'}"
              else
                "imap+insecure";

            port' = optPort imap.port;

          in
          {
            source = "${protocol}://${userName}@${imap.host}${port'}${oauthParams'}";
          }
          // optPwCmd "source" passwordCommand;

        smtp =
          {
            userName,
            smtp,
            passwordCommand,
            ...
          }@cfg:
          let
            loginMethod' = if cfg.aerc.smtpAuth != null then "+${cfg.aerc.smtpAuth}" else "";

            oauthParams' = oauthParams {
              auth = cfg.aerc.smtpAuth;
              params = cfg.aerc.smtpOauth2Params;
            };

            protocol =
              if smtp.tls.enable then
                if smtp.tls.useStartTls then "smtp${loginMethod'}" else "smtps${loginMethod'}"
              else
                "smtp+insecure${loginMethod'}";

            port' = optPort smtp.port;

          in
          {
            outgoing = "${protocol}://${userName}@${smtp.host}${port'}${oauthParams'}";
          }
          // optPwCmd "outgoing" passwordCommand;

        msmtp = cfg: {
          outgoing = "msmtpq --read-envelope-from --read-recipients";
        };

      };

      basicCfg =
        account:
        {
          from = "${account.realName} <${account.address}>";
        }
        // (optAttr "copy-to" account.folders.sent)
        // (optAttr "default" account.folders.inbox)
        // (optAttr "postpone" account.folders.drafts)
        // (optAttr "aliases" account.aliases);

      sourceCfg =
        account:
        if
          account.mbsync.enable && account.mbsync.flatten == null && account.mbsync.subFolders == "Maildir++"
        then
          mkConfig.maildirpp account
        else if account.mbsync.enable || account.offlineimap.enable then
          mkConfig.maildir account
        else if account.imap != null then
          mkConfig.imap account
        else
          { };

      outgoingCfg =
        account:
        if account.msmtp.enable then
          mkConfig.msmtp account
        else if account.smtp != null then
          mkConfig.smtp account
        else
          { };

      gpgCfg =
        account:
        lib.optionalAttrs (account.gpg != null) {
          pgp-key-id = account.gpg.key;
          pgp-auto-sign = account.gpg.signByDefault;
          pgp-opportunistic-encrypt = account.gpg.encryptByDefault;
        };

      signatureCfg =
        account:
        # TODO: aerc does not support attaching signatures yet.
        # Until someone needs it, we will just ignore it for now.
        if account.signature.showSignature == "append" then
          if account.signature.command != null then
            {
              signature-cmd = writeShellScript "aerc-signature.sh" (
                lib.concatStringsSep "\n" [
                  ''printf '%s\n' "${account.signature.delimiter}"''
                  account.signature.command
                ]
              );
            }
          else
            {
              signature-file = writeText "aerc-signature.txt" (
                lib.concatStringsSep "\n" [
                  account.signature.delimiter
                  account.signature.text
                ]
              );
            }
        else
          { };

    in
    builtins.foldl' (acc: f: acc // f account) { } [
      basicCfg
      sourceCfg
      outgoingCfg
      gpgCfg
      signatureCfg
    ]
    // account.aerc.extraAccounts;

  mkAccountConfig = name: account: mapAttrNames (addAccountName name) account.aerc.extraConfig;

  mkAccountBinds = name: account: mapAttrNames (addAccountName name) account.aerc.extraBinds;
}
