{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.zsh.prezto.enable = true;

    nixpkgs.overlays = [
      (self: super: {
        zsh-prezto = super.runCommandLocal "dummy-zsh-prezto" { } ''
          mkdir -p $out/share/zsh-prezto/runcoms
          echo '# zprofile' > $out/share/zsh-prezto/runcoms/zprofile
          echo '# zlogin' > $out/share/zsh-prezto/runcoms/zlogin
          echo '# zlogout' > $out/share/zsh-prezto/runcoms/zlogout
          echo '# zshenv' > $out/share/zsh-prezto/runcoms/zshenv
        '';
      })
    ];

    nmt.script = ''
      assertFileExists home-files/.zpreztorc
    '';
  };
}
