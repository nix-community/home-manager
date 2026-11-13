{ config, lib, ... }:
let
  expectedIgnore = [
    ".uidvalidity"
    ".mbsyncstate"
    "/.*[.](json|lock|bak)$/"
    "/.*[.](toml|json|lock)$/"
    "manual"
  ];
in
{
  programs.mbsync.enable = true;
  programs.lieer.enable = true;
  programs.mujmap.enable = true;
  programs.notmuch = {
    enable = true;
    settings = {
      new.ignore = [ "manual" ];
      user.name = "All Sync Producers";
      user.primary_email = "sync@example.com";
    };
  };

  assertions = [
    {
      assertion =
        lib.sort builtins.lessThan config.programs.notmuch.settings.new.ignore
        == lib.sort builtins.lessThan expectedIgnore;
      message = "Sync producers and native settings must concatenate without the default.";
    }
  ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileContains home-files/.config/notmuch/default/config 'ignore=${lib.concatStringsSep ";" config.programs.notmuch.settings.new.ignore}'
  '';
}
