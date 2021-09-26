{ config, lib, pkgs, ... }:

with lib;

{
  programs.zsh.prezto.enable = true;

  test.stubs.zsh-prezto = {
    outPath = null;
    buildScript = ''
      mkdir -p $out/share/zsh-prezto/runcoms
      echo '# zprofile' > $out/share/zsh-prezto/runcoms/zprofile
      echo '# zlogin' > $out/share/zsh-prezto/runcoms/zlogin
      echo '# zlogout' > $out/share/zsh-prezto/runcoms/zlogout
      echo '# zshenv' > $out/share/zsh-prezto/runcoms/zshenv
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.zpreztorc
  '';
}
