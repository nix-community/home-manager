{ config, lib, pkgs, confSections, confSection, ... }:

with lib;

let
  mapAttrNames = f: attr:
    with builtins;
    listToAttrs (attrValues (mapAttrs (k: v: {
      name = f k;
      value = v;
    }) attr));

  addAccountName = name: k: "${k}:account=${name}";

  oauth2Params = mkOption {
    type = with types;
      nullOr (submodule {
        options = {
          token_endpoint = mkOption {
            type = nullOr str;
            default = null;
          };
          client_id = mkOption {
            type = nullOr str;
            default = null;
          };
          client_secret = mkOption {
            type = nullOr str;
            default = null;
          };
          scope = mkOption {
            type = nullOr str;
            default = null;
          };
        };
      });
    default = null;
    example = { token_endpoint = "<token_endpoint>"; };
    description = ''
      Sets the oauth2 params if authentication mechanism oauthbearer or
      xoauth2 is used.
      See <citerefentry><refentrytitle>aerc-imap</refentrytitle><manvolnum>5</manvolnum></citerefentry>.
    '';
  };

in {
  type = mkOption {
    type = types.attrsOf (types.submodule {
      options.aerc = {
        enable = mkEnableOption "aerc";
        extraAccounts = mkOption {
          type = confSection;
          default = { };
          example =
            literalExpression ''{ source = "maildir://~/Maildir/example"; }'';
          description = ''
            Extra config added to the configuration of this account in
            <filename>$HOME/.config/aerc/accounts.conf</filename>.
            See aerc-config(5).
          '';
        };
        extraBinds = mkOption {
          type = confSections;
          default = { };
          example = literalExpression
            ''{ messages = { d = ":move ''${folder.trash}<Enter>"; }; }'';
          description = ''
            Extra bindings specific to this account, added to
            <filename>$HOME/.config/aerc/accounts.conf</filename>.
            See <citerefentry><refentrytitle>aerc-config</refentrytitle><manvolnum>5</manvolnum></citerefentry>.
          '';
        };
        extraConfig = mkOption {
          type = confSections;
          default = { };
          example = literalExpression "{ ui = { sidebar-width = 42; }; }";
          description = ''
            Extra config specific to this account, added to
            <filename>$HOME/.config/aerc/aerc.conf</filename>.
            See <citerefentry><refentrytitle>aerc-config</refentrytitle><manvolnum>5</manvolnum></citerefentry>.
          '';
        };

        imapAuth = mkOption {
          type = with types; nullOr (enum [ "oauthbearer" "xoauth2" ]);
          default = null;
          example = "auth";
          description = ''
            Sets the authentication mechanism if imap is used as the incoming
            method.
            See <citerefentry><refentrytitle>aerc-imap</refentrytitle><manvolnum>5</manvolnum></citerefentry>.
          '';
        };

        imapOauth2Params = oauth2Params;

        smtpAuth = mkOption {
          type = with types;
            nullOr (enum [ "none" "plain" "login" "oauthbearer" "xoauth2" ]);
          default = "plain";
          example = "auth";
          description = ''
            Sets the authentication mechanism if smtp is used as the outgoing
            method.
            See <citerefentry><refentrytitle>aerc-smtp</refentrytitle><manvolnum>5</manvolnum></citerefentry>.
          '';
        };

        smtpOauth2Params = oauth2Params;
      };
    });
  };
  mkAccount = name: account:
    let
      nullOrMap = f: v: if v == null then v else f v;
      optPort = port: if port != null then ":${toString port}" else "";
      optAttr = k: v:
        if v != null && v != [ ] && v != "" then { ${k} = v; } else { };
      optPwCmd = k: p:
        optAttr "${k}-cred-cmd" (nullOrMap (builtins.concatStringsSep " ") p);

      useOauth = auth: builtins.elem auth [ "oauthbearer" "xoauth2" ];

      oauthParams = { auth, params }:
        if useOauth auth && params != null && params != { } then
          "?" + builtins.concatStringsSep "&" lib.attrsets.mapAttrsToList
          (k: v: k + "=" + lib.strings.escapeURL v) params
        else
          "";

      mkConfig = {
        maildir = cfg: {
          source =
            "maildir://${config.accounts.email.maildirBasePath}/${cfg.maildir.path}";
        };
        imap = { userName, imap, passwordCommand, aerc, ... }@cfg:
          let
            loginMethod' =
              if cfg.aerc.imapAuth != null then "+${cfg.aerc.imapAuth}" else "";

            oauthParams' = oauthParams {
              auth = cfg.aerc.imapAuth;
              params = cfg.aerc.imapOauth2Params;
            };

            protocol = if imap.tls.enable then
              if imap.tls.useStartTls then "imap" else "imaps${loginMethod'}"
            else
              "imap+insecure";
            port' = optPort imap.port;
          in {
            source =
              "${protocol}://${userName}@${imap.host}${port'}${oauthParams'}";
          } // optPwCmd "source" passwordCommand;
        smtp = { userName, smtp, passwordCommand, ... }@cfg:
          let
            loginMethod' =
              if cfg.aerc.smtpAuth != null then "+${cfg.aerc.smtpAuth}" else "";

            oauthParams' = oauthParams {
              auth = cfg.aerc.smtpAuth;
              params = cfg.aerc.smtpOauth2Params;
            };

            protocol = if smtp.tls.enable && !smtp.tls.useStartTls then
              "smtps${loginMethod'}"
            else
              "smtp${loginMethod'}";
            port' = optPort smtp.port;
            smtp-starttls =
              if smtp.tls.enable && smtp.tls.useStartTls then "yes" else null;
          in {
            outgoing =
              "${protocol}://${userName}@${smtp.host}${port'}${oauthParams'}";
          } // optPwCmd "outgoing" passwordCommand
          // optAttr "smtp-starttls" smtp-starttls;
        msmtp = cfg: {
          outgoing = "msmtpq --read-envelope-from --read-recipients";
        };
      };
      basicCfg = account:
        {
          from = "${account.realName} <${account.address}>";
        } // (optAttr "copy-to" account.folders.sent)
        // (optAttr "default" account.folders.inbox)
        // (optAttr "postpone" account.folders.drafts)
        // (optAttr "aliases" account.aliases) // account.aerc.extraAccounts;
      sourceCfg = account:
        if account.mbsync.enable || account.offlineimap.enable then
          mkConfig.maildir account
        else if account.imap != null then
          mkConfig.imap account
        else
          { };
      outgoingCfg = account:
        if account.msmtp.enable then
          mkConfig.msmtp account
        else if account.smtp != null then
          mkConfig.smtp account
        else
          { };
    in (basicCfg account) // (sourceCfg account) // (outgoingCfg account);
  mkAccountConfig = name: account:
    mapAttrNames (addAccountName name) account.aerc.extraConfig;
  mkAccountBinds = name: account:
    mapAttrNames (addAccountName name) account.aerc.extraBinds;
}
