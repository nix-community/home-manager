{ lib, options, ... }:
{
  imports = [
    ../../accounts/email-test-accounts.nix
    {
      programs.notmuch.extraConfig.new.tags = lib.mkDefault "overlay-tag";
    }
    {
      programs.notmuch.extraConfig.new = lib.mkIf true {
        disabled = lib.mkIf false "unused";
      };
    }
  ];

  accounts.email.accounts."hm@example.com".notmuch.enable = true;

  programs.mbsync.enable = true;
  programs.notmuch = {
    enable = true;
    new.ignore = [ "legacy-ignore" ];
    extraConfig = {
      user = {
        name = "Legacy Name";
        primary_email = "legacy@example.com";
      };
      maildir.synchronize_flags = "true";
      search.exclude_tags = "overlay-excluded";
      show.extra_headers = "";
    };
  };

  test.asserts.warnings.expected = [
    "The option `programs.notmuch.extraConfig' defined in ${lib.showFiles options.programs.notmuch.extraConfig.files} has been renamed to `programs.notmuch.settings'."
    "The option `programs.notmuch.new.ignore' defined in ${lib.showFiles options.programs.notmuch.new.ignore.files} has been renamed to `programs.notmuch.settings.new.ignore'."
  ];

  nmt.script = ''
    assertFileContent home-files/.config/notmuch/default/config ${./legacy-expected.conf}
  '';
}
