{ config, lib, ... }:

with lib;

{
  config = {
    home.stateVersion = "19.03";
    programs.zsh.enable = true;

    test.stubs.zsh = { };

    nmt.script = ''
      assertFileRegex home-files/.zshrc '^HISTFILE="$HOME/.zsh_history"$'
    '';
  };
}
