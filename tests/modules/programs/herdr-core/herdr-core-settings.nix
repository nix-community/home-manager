{ config, ... }:
{
  xdg.enable = true;

  programs.herdr.core = {
    enable = true;
    package = config.lib.test.mkStubPackage { name = "herdr-core"; };

    settings = {
      shell = [
        "nu"
        "-l"
      ];
      notes = true;
      notes_quiet = 3;
      draft_wait = 60;
      restore_screen = true;
      history_mb = 5;
    };
  };

  test.asserts.warnings.expected = [ ];

  nmt.script = ''
    assertFileExists "home-files/.config/herdr-core/config.toml"
    assertFileContent \
      "home-files/.config/herdr-core/config.toml" \
      ${./settings-expected.toml}
  '';
}
