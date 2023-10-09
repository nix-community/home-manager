{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    test.asserts.assertions.expected = [''
      Only the ui section of $XDG_CONFIG_HOME/aerc.conf supports contextual (per-account) configuration.
      Please configure it with accounts.email.accounts._.aerc.extraConfig.ui and move any other
      configuration to programs.aerc.extraConfig.
    ''];
    test.asserts.warnings.expected = [''
      aerc: `programs.aerc.enable` is set, but `...extraConfig.general.unsafe-accounts-conf` is set to false or unset.
      This will prevent aerc from starting; see `unsafe-accounts-conf` in the man page aerc-config(5):
      > By default, the file permissions of accounts.conf must be restrictive and only allow reading by the file owner (0600).
      > Set this option to true to ignore this permission check. Use this with care as it may expose your credentials.
      These permissions are not possible with home-manager, since the generated file is in the nix-store (permissions 0444).
      Therefore, please set `programs.aerc.extraConfig.general.unsafe-accounts-conf = true`.
      This option is safe; if `passwordCommand` is properly set, no credentials will be written to the nix store.
    ''];

    test.stubs.aerc = { };

    programs.aerc = {
      enable = true;
      extraAccounts = {
        Test1 = {
          source = "maildir:///dev/null";
          enable-folders-sort = true;
          folders = [ "INBOX" "SENT" "JUNK" ];
        };
      };
      extraConfig.general = {
        # unsafe-accounts-conf = true;
        pgp-provider = "gpg";
      };
    };

    accounts.email.accounts.Test2 = {
      address = "addr@mail.invalid";
      userName = "addr@mail.invalid";
      realName = "Foo Bar";
      primary = true;
      imap.host = "imap.host.invalid";
      passwordCommand = "echo PaSsWorD!";
      aerc = {
        enable = true;
        extraConfig.general.pgp-provider = "internal";
      };
    };
  };
}
