{ lib, ... }:
{
  programs.notmuch = {
    enable = true;
    settings = {
      database.path = lib.mkForce "/mail";
      user.name = "Native Name";
      user.primary_email = "native@example.com";
      show.extra_headers = lib.mkBefore [ "List-Id" ];
      new.ignore = lib.mkBefore [ "native-before" ];
      new.tags = lib.mkDefault [ "custom" ];
      maildir.synchronize_flags = lib.mkDefault true;
      search.exclude_tags = lib.mkIf false [ "unused" ];
      custom.absent = lib.mkIf false "unused";
      custom.enabled = true;
      custom.count = 3;
      custom.empty = "";
      user.other_email = null;
    };
    hooks = {
      preNew = "mbsync --all";
      postNew = "notmuch tag -new tag:new";
      postInsert = "notmuch tag +inserted tag:new";
    };
  };

  imports = [
    {
      programs.notmuch.settings = {
        show.extra_headers = lib.mkAfter [ "Mailing-List" ];
        new.ignore = lib.mkAfter [ "native-after" ];
      };
    }
  ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileRegex home-files/.config/notmuch/default/config '^path=/mail$'
    assertFileRegex home-files/.config/notmuch/default/config '^name=Native Name$'
    assertFileRegex home-files/.config/notmuch/default/config '^primary_email=native@example.com$'
    assertFileRegex home-files/.config/notmuch/default/config '^extra_headers=List-Id;Mailing-List$'
    assertFileRegex home-files/.config/notmuch/default/config '^ignore=native-before;native-after$'
    assertFileRegex home-files/.config/notmuch/default/config '^tags=custom$'
    assertFileRegex home-files/.config/notmuch/default/config '^synchronize_flags=true$'
    assertFileRegex home-files/.config/notmuch/default/config '^exclude_tags=deleted;spam$'
    assertFileRegex home-files/.config/notmuch/default/config '^enabled=true$'
    assertFileRegex home-files/.config/notmuch/default/config '^count=3$'
    assertFileRegex home-files/.config/notmuch/default/config '^empty=$'
    assertFileNotRegex home-files/.config/notmuch/default/config '^absent='
    assertFileNotRegex home-files/.config/notmuch/default/config '^other_email='
    assertFileExists home-files/.config/notmuch/default/hooks/pre-new
    assertFileExists home-files/.config/notmuch/default/hooks/post-new
    assertFileExists home-files/.config/notmuch/default/hooks/post-insert
  '';
}
