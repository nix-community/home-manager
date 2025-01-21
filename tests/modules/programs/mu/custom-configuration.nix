{ config, ... }: {
  imports = [ ../../accounts/email-test-accounts.nix ];

  accounts.email.accounts = {
    "hm@example.com" = {
      mu.enable = true;
      aliases = [ "foo@example.com" ];
    };
  };

  programs.mu = {
    enable = true;
    home = config.xdg.dataHome + "/mu";
  };

  test.stubs.mu = { name = "mu"; };

  nmt.script = ''
    assertFileContains activate \
      'if [[ ! -d "/home/hm-user/.local/share/mu" || ! "$MU_SORTED_ADDRS" = "foo@example.com hm@example.com" ]]; then'

    assertFileContains activate \
      'run @mu@/bin/mu init --maildir=/home/hm-user/Mail --muhome "/home/hm-user/.local/share/mu" --my-address=foo@example.com --my-address=hm@example.com $VERBOSE_ARG;'
  '';
}
