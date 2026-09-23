{ lib, ... }:
{
  imports = [
    ../../accounts/email-test-accounts.nix
    {
      programs.notmuch.settings = {
        user.name = "Discarded Name";
        new.tags = [ "discarded" ];
        custom.discarded = true;
      };
    }
  ];

  programs.notmuch = {
    enable = true;
    settings = lib.mkForce {
      user.name = "Forced Name";
      user.primary_email = "forced@example.com";
      new.ignore = [ ];
    };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileRegex home-files/.config/notmuch/default/config '^name=Forced Name$'
    assertFileRegex home-files/.config/notmuch/default/config '^primary_email=forced@example.com$'
    assertFileRegex home-files/.config/notmuch/default/config '^ignore=$'
    assertFileNotRegex home-files/.config/notmuch/default/config '^tags='
    assertFileNotRegex home-files/.config/notmuch/default/config '^discarded='
    assertFileNotRegex home-files/.config/notmuch/default/config '^path='
    assertFileNotRegex home-files/.config/notmuch/default/config '^exclude_tags='
  '';
}
