{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    home.stateVersion = "20.03";
    programs.zsh.enable = true;

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileRegex home-files/.zshrc '^HISTFILE="$HOME/.zsh_history"$'
    '';
  };
}
