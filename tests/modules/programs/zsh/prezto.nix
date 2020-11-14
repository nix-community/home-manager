{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.zsh.prezto.enable = true;

    nixpkgs.overlays = [
      (self: super: {
        zsh-prezto = super.runCommandLocal "dummy-zsh-prezto" { } ''
          mkdir -p $out/runcoms
          echo '# zprofile' > $out/runcoms/zprofile
          echo '# zlogin' > $out/runcoms/zlogin
          echo '# zlogout' > $out/runcoms/zlogout
          echo '# zshenv' > $out/runcoms/zshenv
        '';
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.zpreztorc
    '';
  };
}
