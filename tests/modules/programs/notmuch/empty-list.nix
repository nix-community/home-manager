{ lib, ... }:
{
  home.stateVersion = "26.11";
  programs.mbsync.enable = true;
  programs.lieer.enable = true;
  programs.mujmap.enable = true;
  programs.notmuch = {
    enable = true;
    settings = {
      user.name = "Empty Lists";
      user.primary_email = "empty@example.com";
      new.ignore = lib.mkForce [ ];
      new.tags = [ ];
      search.exclude_tags = [ ];
      user.other_email = [ ];
    };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileRegex home-files/.config/notmuch/default/config '^ignore=$'
    assertFileRegex home-files/.config/notmuch/default/config '^tags=$'
    assertFileRegex home-files/.config/notmuch/default/config '^exclude_tags=$'
    assertFileRegex home-files/.config/notmuch/default/config '^other_email=$'
    assertFileNotRegex home-files/.config/notmuch/default/config '^path='
    assertFileNotRegex home-files/.config/notmuch/default/config '^\[database\]$'
  '';
}
