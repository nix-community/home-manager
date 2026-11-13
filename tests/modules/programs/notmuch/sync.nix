sync:
{ config, lib, ... }:
let
  ignores = {
    lieer = [ "/.*[.](json|lock|bak)$/" ];
    mbsync = [
      ".uidvalidity"
      ".mbsyncstate"
    ];
    mujmap = [ "/.*[.](toml|json|lock)$/" ];
  };
in
{
  programs.${sync}.enable = true;
  programs.notmuch = {
    enable = true;
    settings.user = {
      name = "Sync User";
      primary_email = "sync@example.com";
    };
  };

  assertions = [
    {
      assertion = config.programs.notmuch.settings.new.ignore == ignores.${sync};
      message = "The sync module must contribute native ignore patterns.";
    }
  ];

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileContains home-files/.config/notmuch/default/config 'ignore=${
      lib.concatStringsSep ";" ignores.${sync}
    }'
    assertFileNotRegex home-files/.config/notmuch/default/config '^tags='
  '';
}
