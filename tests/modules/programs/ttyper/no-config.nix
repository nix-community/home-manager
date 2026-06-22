{ pkgs, ... }:
{
  programs.ttyper = {
    enable = true;
    package = pkgs.writeScriptBin "dummy-ttyper" "";
  };

  nmt.script = ''
    assertPathNotExists home-files/.config/ttyper/config.toml
  '';
}
