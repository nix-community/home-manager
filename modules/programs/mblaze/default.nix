{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.programs.mblaze;

  enabledAccounts = lib.filterAttrs (
    _: account: account.enable && account.mblaze.enable
  ) config.accounts.email.accounts;

  # exactly one account is primary, asserted in modules/accounts/email.nix,
  # and it may be one that leaves mblaze disabled, in which case no account
  # owns ~/.mblaze
  primaryAccountName = lib.findFirst (name: enabledAccounts.${name}.primary) null (
    lib.attrNames enabledAccounts
  );

  # mblaze reads one profile, from $MBLAZE or from ~/.mblaze when that is unset,
  # so an account is selected by pointing $MBLAZE at its own directory. The
  # primary account is written to both places, which keeps a bare `mcom` working
  # with no environment set up.
  accountDir = name: "${config.xdg.configHome}/mblaze/${name}";
  stateDir = name: "${config.xdg.dataHome}/mblaze/${name}";

  # `maildir` carries a default path for every account whether or not anything
  # ever populates it, so a local maildir only counts once a synchroniser is set
  # up to fill it
  hasLocalMaildir =
    account:
    !isNull account.maildir
    && (
      account.mbsync.enable
      || account.offlineimap.enable
      || account.getmail.enable
      || account.lieer.enable
      || account.mujmap.enable
    );

  mkMailbox = account: "${account.realName} <${account.address}>";

  mkAliases =
    account: map (alias: if lib.isString alias then alias else alias.address) account.aliases;

  mkDrafts =
    name: account:
    if hasLocalMaildir account && !isNull account.folders.drafts then
      "${account.maildir.absPath}/${account.folders.drafts}"
    else
      "${stateDir name}/drafts";

  mkOutbox =
    account:
    if !hasLocalMaildir account || isNull account.folders.sent then
      null
    else
      "${account.maildir.absPath}/${account.folders.sent}";

  mkProfile =
    name: account:
    let
      aliases = mkAliases account;

      entries = lib.filterAttrs (_: value: !isNull value) (
        {
          Local-Mailbox = mkMailbox account;
          Reply-From = mkMailbox account;
          Alternate-Mailboxes = if aliases == [ ] then null else lib.concatStringsSep ", " aliases;
          FQDN = lib.last (lib.splitString "@" account.address);
          Maildir = if hasLocalMaildir account then account.maildir.absPath else null;
          Drafts = mkDrafts name account;
          Outbox = mkOutbox account;
          Sendmail = account.mblaze.sendMailCommand;
          Editor = cfg.editor;
        }
        // cfg.settings
        // account.mblaze.settings
      );
    in
    lib.concatStringsSep "\n" (lib.mapAttrsToList (key: value: "${key}: ${value}") entries) + "\n";

  mkSignature =
    account:
    if
      account.signature.showSignature == "append"
      && isNull account.signature.command
      && account.signature.text != ""
    then
      account.signature.text
    else
      null;

  mkFiles =
    dir: name: account:
    {
      "${dir}/profile".text = mkProfile name account;
    }
    // lib.optionalAttrs (!isNull (mkSignature account)) {
      "${dir}/signature".text = mkSignature account;
    };

in
{
  meta.maintainers = [ lib.maintainers.soywod ];

  options = {
    programs.mblaze = {
      enable = lib.mkEnableOption "mblaze, unix utilities to deal with Maildir";

      package = lib.mkPackageOption pkgs "mblaze" { };

      editor = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "nvim";
        description = ''
          Editor {manpage}`mcom(1)` opens drafts with, written to the
          `Editor:` entry of every generated profile. When left null
          mblaze falls back to {env}`MBLAZE_EDITOR`, then {env}`VISUAL`,
          then {env}`EDITOR`.
        '';
      };

      settings = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          Scan-Format = "%c%u%r %-3n %10d %17f %t %2i%s";
        };
        description = ''
          Entries added to every generated profile, as documented in
          {manpage}`mblaze-profile(5)`. An entry defined here overrides
          the generated one of the same name, and is in turn overridden
          by [](#opt-accounts.email.accounts._name_.mblaze.settings).
        '';
      };

      accountDirs = mkOption {
        type = types.attrsOf types.str;
        default = { };
        internal = true;
        description = ''
          Generated map of account name to the directory holding that
          account's profile, to be exported as {env}`MBLAZE`. Read by
          modules that drive mblaze on behalf of another program.
        '';
      };
    };

    accounts.email.accounts = mkOption {
      type = with types; attrsOf (submodule (import ./accounts.nix));
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.mblaze.accountDirs = lib.mapAttrs (name: _: accountDir name) enabledAccounts;

    xdg.configFile = lib.mkMerge (
      lib.mapAttrsToList (name: account: mkFiles "mblaze/${name}" name account) enabledAccounts
    );

    # ~/.mblaze is where mblaze looks when $MBLAZE is unset, so the primary
    # account is reachable without any environment set up
    home.file = lib.optionalAttrs (!isNull primaryAccountName) (
      mkFiles ".mblaze" primaryAccountName enabledAccounts.${primaryAccountName}
    );

    # `Drafts:` has to exist before mcom can deliver a draft into it, and
    # mdeliver does not create it
    home.activation.mblazeDrafts = lib.mkIf (enabledAccounts != { }) (
      lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        run ${cfg.package}/bin/mmkdir ${lib.escapeShellArgs (lib.mapAttrsToList mkDrafts enabledAccounts)}
      ''
    );
  };
}
