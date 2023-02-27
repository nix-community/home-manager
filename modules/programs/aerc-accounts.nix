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
            See aerc-config(5).
          '';
        };
        extraConfig = mkOption {
          type = confSections;
          default = { };
          example = literalExpression "{ ui = { sidebar-width = 42; }; }";
          description = ''
            Extra config specific to this account, added to
            <filename>$HOME/.config/aerc/aerc.conf</filename>.
            See aerc-config(5).
          '';
        };
        smtpAuth = mkOption {
          type = with types;
            nullOr (enum [ "none" "plain" "login" "oauthbearer" "xoauth2" ]);
          default = "plain";
          example = "auth";
          description = ''
            Sets the authentication mechanism if smtp is used as the outgoing
            method.
            See aerc-smtp(5).
          '';
        };
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
      mkConfig = {
        maildir = cfg: {
          source =
            "maildir://${config.accounts.email.maildirBasePath}/${cfg.maildir.path}";
        };
        imap = { userName, imap, passwordCommand, aerc, ... }@cfg:
          let
            protocol = if imap.tls.enable then
              if imap.tls.useStartTls then "imap" else "imaps"
            else
              "imap+insecure";
            port' = optPort imap.port;
          in {
            source = "${protocol}://${userName}@${imap.host}${port'}";
          } // optPwCmd "source" passwordCommand;
        smtp = { userName, smtp, passwordCommand, ... }@cfg:
          let
            loginMethod' =
              if cfg.aerc.smtpAuth != null then "+${cfg.aerc.smtpAuth}" else "";
            protocol = if smtp.tls.enable && !smtp.tls.useStartTls then
              "smtps${loginMethod'}"
            else
              "smtp${loginMethod'}";
            port' = optPort smtp.port;
            smtp-starttls =
              if smtp.tls.enable && smtp.tls.useStartTls then "yes" else null;
          in {
            outgoing = "${protocol}://${userName}@${smtp.host}${port'}";
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
