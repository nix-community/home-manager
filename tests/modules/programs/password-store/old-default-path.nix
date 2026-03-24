{ config, ... }:
{
  home.stateVersion = "25.05"; # <= 25.11
  programs.password-store.enable = true;

  test.asserts.warnings.expected = [
    ''
      The default value of `programs.password-store.settings` has changed from `{ PASSWORD_STORE_DIR = "$XDG_DATA_HOME/password-store"; }` to `{ }`.
      You are currently using the legacy default (`{ PASSWORD_STORE_DIR = "$XDG_DATA_HOME/password-store"; }`) because `home.stateVersion` is less than "25.11".
      To silence this warning and keep legacy behavior, set:
        programs.password-store.settings = { PASSWORD_STORE_DIR = "$XDG_DATA_HOME/password-store"; };
      To adopt the new default behavior, set:
        programs.password-store.settings = { };
    ''
  ];

  nmt.script = ''
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      'export PASSWORD_STORE_DIR="${config.xdg.dataHome}/password-store"'
  '';
}
