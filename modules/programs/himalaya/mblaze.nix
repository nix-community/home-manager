{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (config.programs) himalaya mblaze;
  inherit (lib)
    attrNames
    concatStringsSep
    elem
    escapeShellArg
    filterAttrs
    getExe
    mapAttrsToList
    mkDefault
    mkIf
    mkOption
    optional
    optionalString
    types
    ;

  cfg = himalaya.mblaze;
  enabled = himalaya.enable && mblaze.enable;
  himalayaExe = if isNull himalaya.package then "himalaya" else getExe himalaya.package;

  composedAccounts = filterAttrs (
    _: account: account.enable && account.himalaya.enable && account.mblaze.enable
  ) config.accounts.email.accounts;

  primaryAccounts = attrNames (filterAttrs (_: account: account.primary) composedAccounts);

  accountsWithoutSentFolder = attrNames (
    filterAttrs (_: account: isNull account.folders.sent) composedAccounts
  );

  mkAccountArm =
    name: dir:
    let
      patterns = concatStringsSep " | " (
        optional (elem name primaryAccounts) ''""'' ++ [ (escapeShellArg name) ]
      );
    in
    "  ${patterns}) export MBLAZE=${escapeShellArg dir} ;;";

  mkSendMailCommand =
    name:
    "${himalayaExe} --account ${escapeShellArg name} message send"
    + optionalString cfg.saveSent " --save sent";

  mkWrappers =
    let
      accountDirs = filterAttrs (name: _: composedAccounts ? ${name}) mblaze.accountDirs;

      account = ''
        account="''${HIMALAYA_ACCOUNT:-}"

        while [ "$#" -gt 0 ]; do
          case "$1" in
            -a | --account)
              account="$2"
              shift 2
              ;;
            --account=*)
              account="''${1#*=}"
              shift
              ;;
            *)
              break
              ;;
          esac
        done

        case "$account" in
        ${concatStringsSep "\n" (mapAttrsToList mkAccountArm accountDirs)}
          *)
            echo "$(basename "$0"): no mblaze account named ''${account:-<default>}" >&2
            exit 1
            ;;
        esac
      '';

      fetch = ''
        if [ "$#" -eq 0 ]; then
          echo "usage: $(basename "$0") [-a ACCOUNT] <ID> [himalaya flags...]" >&2
          exit 1
        fi

        msg=$(mktemp)
        trap 'rm -f "$msg"' EXIT HUP INT TERM

        ${himalayaExe} --account "$account" message read --raw "$@" >"$msg"
      '';

      mkWrapper =
        name: body:
        pkgs.writeShellApplication {
          inherit name;
          runtimeInputs = [
            mblaze.package
            pkgs.coreutils
          ];
          text = concatStringsSep "\n" [
            account
            body
          ];
        };
    in
    [
      (mkWrapper "himalaya-mcom" ''
        mcom "$@"
      '')
      (mkWrapper "himalaya-mrep" ''
        ${fetch}
        mrep "$msg"
      '')
      (mkWrapper "himalaya-mfwd" ''
        ${fetch}
        mfwd "$msg"
      '')
      (mkWrapper "himalaya-mshow" ''
        ${fetch}
        mshow "$msg"
      '')
    ];

in
{
  options.programs.himalaya.mblaze.saveSent = mkOption {
    type = types.bool;
    default = true;
    description = ''
      Whether a copy of every message sent from {manpage}`mcom(1)` is
      appended to the account's sent mailbox, passed as
      {command}`himalaya message send --save sent`.

      `sent` is resolved through the account's `[mailbox.alias]` map, which the
      module fills in from  [](#opt-accounts.email.accounts._name_.folders.sent).
      An account that has no sent mailbox is an error rather than a message
      silently sent without a copy.

      Turn this off when the server files its own copy, as a JMAP
      submission does.
    '';
  };

  options.accounts.email.accounts = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, config, ... }:
        {
          config.mblaze.sendMailCommand = mkIf (
            enabled && config.himalaya.enable && config.mblaze.enable && !config.msmtp.enable
          ) (mkDefault (mkSendMailCommand name));
        }
      )
    );
  };

  config = mkIf enabled {
    assertions = [
      {
        assertion = cfg.saveSent -> accountsWithoutSentFolder == [ ];
        message = ''
          programs.himalaya.mblaze.saveSent has no mailbox to save to on these
          accounts, as accounts.email.accounts.<name>.folders.sent is null:
          ${concatStringsSep ", " accountsWithoutSentFolder}.
        '';
      }
    ];

    home.packages = mkWrappers;
  };
}
