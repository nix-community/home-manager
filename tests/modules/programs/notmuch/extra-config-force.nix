{ lib, options, ... }:
{
  programs.mbsync.enable = true;
  programs.notmuch = {
    enable = true;
    extraConfig = lib.mkForce {
      new.ignore = [ "forced" ];
      user = {
        name = "Forced User";
        primary_email = "forced@example.com";
      };
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.notmuch.extraConfig' defined in ${lib.showFiles options.programs.notmuch.extraConfig.files} has been renamed to `programs.notmuch.settings'."
  ];

  nmt.script = ''
    assertFileRegex home-files/.config/notmuch/default/config '^ignore=forced$'
    assertFileNotRegex home-files/.config/notmuch/default/config '^tags='
    assertFileRegex home-files/.config/notmuch/default/config '^name=Forced User$'
    assertFileNotRegex home-files/.config/notmuch/default/config '^synchronize_flags='
    assertFileRegex home-files/.config/notmuch/default/config '^exclude_tags=deleted;spam$'
    assertFileRegex home-files/.config/notmuch/default/config '^path=/home/hm-user/Maildir$'
  '';
}
