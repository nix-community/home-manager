{ ... }:

{
  imports = [ ./zsh-stubs.nix ];

  programs.zsh.prezto.enable = true;

  nmt.script = ''
    assertFileExists home-files/.zpreztorc
  '';
}
