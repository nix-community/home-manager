{ pkgs, ... }:
{
  programs.macchina = {
    enable = true;
    package = pkgs.writeScriptBin "dummy-macchina" "";
  };

  nmt.script = ''
    assertFileExists home-files/.config/macchina/macchina.toml
    assertFileContent \
      home-files/.config/macchina/macchina.toml \
      ${./no-config.toml}
    assertPathNotExists home-files/.config/macchina/themes
  '';
}
