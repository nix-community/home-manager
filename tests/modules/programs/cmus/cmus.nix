{ config, lib, pkgs, ... }:
with lib; {
  config = {
    programs.cmus = {
      enable = true;
      theme = "gruvbox";
      extraConfig = "test";
    };
    nmt.script = ''
      assertFileContent \
        home-files/.config/cmus/rc \
        ${./rc}
    '';
  };
}
