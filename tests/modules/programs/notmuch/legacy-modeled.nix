{ lib, options, ... }:
{
  imports = [
    ../../accounts/email-test-accounts.nix
    {
      programs.notmuch = {
        new.tags = lib.mkAfter [ "after" ];
        new.ignore = lib.mkDefault [ "weak" ];
        settings.new.tags = lib.mkIf false [ "unused" ];
      };
    }
  ];

  accounts.email.accounts."hm@example.com".notmuch.enable = true;

  programs.notmuch = {
    enable = true;
    new = {
      ignore = [ "legacy-ignore" ];
      tags = lib.mkBefore [ "before" ];
    };
    maildir.synchronizeFlags = lib.mkDefault false;
    search.excludeTags = [ "legacy-excluded" ];
    settings = lib.mkDefault { };
  };

  test.asserts.warnings.expected = [
    "The option `programs.notmuch.search.excludeTags' defined in ${lib.showFiles options.programs.notmuch.search.excludeTags.files} has been renamed to `programs.notmuch.settings.search.exclude_tags'."
    "The option `programs.notmuch.maildir.synchronizeFlags' defined in ${lib.showFiles options.programs.notmuch.maildir.synchronizeFlags.files} has been renamed to `programs.notmuch.settings.maildir.synchronize_flags'."
    "The option `programs.notmuch.new.tags' defined in ${lib.showFiles options.programs.notmuch.new.tags.files} has been renamed to `programs.notmuch.settings.new.tags'."
    "The option `programs.notmuch.new.ignore' defined in ${lib.showFiles options.programs.notmuch.new.ignore.files} has been renamed to `programs.notmuch.settings.new.ignore'."
  ];

  nmt.script = ''
    assertFileRegex home-files/.config/notmuch/default/config '^ignore=legacy-ignore$'
    assertFileRegex home-files/.config/notmuch/default/config '^tags=before;after$'
    assertFileRegex home-files/.config/notmuch/default/config '^synchronize_flags=false$'
    assertFileRegex home-files/.config/notmuch/default/config '^exclude_tags=legacy-excluded$'
  '';
}
