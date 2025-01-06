{ ... }:

{
  imports = [ ./zsh-stubs.nix ];

  config = {
    home.stateVersion = "19.03";
    programs.zsh.enable = true;

    nmt.script = ''
      assertFileRegex home-files/.zshrc '^HISTFILE="$HOME/.zsh_history"$'
    '';
  };
}
