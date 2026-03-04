{ pkgs, ... }:
{
  programs.macchina = {
    enable = true;
    package = pkgs.writeScriptBin "dummy-macchina" "";
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/macchina/macchina.toml
    assertPathNotExists home-files/.config/macchina/themes
  '';
}
