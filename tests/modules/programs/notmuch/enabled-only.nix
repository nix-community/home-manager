stateVersion:
{ lib, ... }:
{
  imports = [ ../../accounts/email-test-accounts.nix ];

  home.stateVersion = stateVersion;
  accounts.email.accounts."hm@example.com".notmuch.enable = true;
  programs.notmuch.enable = true;

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileContent home-files/.config/notmuch/default/config ${
      if lib.versionOlder stateVersion "26.11" then
        ./enabled-only-expected.conf
      else
        ./enabled-only-26-11-expected.conf
    }
  '';
}
