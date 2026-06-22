{ pkgs, ... }:
{
  programs.ttyper = {
    enable = true;
    package = pkgs.writeScriptBin "dummy-ttyper" "";

    settings.default_language = "english1000";
  };

  nmt.script = ''
    assertFileExists home-files/.config/ttyper/config.toml
    assertFileContent \
      home-files/.config/ttyper/config.toml \
      ${./basic-settings-expected.toml}
  '';
}
