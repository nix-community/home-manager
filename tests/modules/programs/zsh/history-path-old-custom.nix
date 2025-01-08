{ ... }:

{
  imports = [ ./zsh-stubs.nix ];

  config = {
    home.stateVersion = "19.09";
    programs.zsh = {
      enable = true;
      history.path = "some/directory/zsh_history";
    };

    nmt.script = ''
      assertFileRegex home-files/.zshrc '^HISTFILE="$HOME/some/directory/zsh_history"$'
    '';
  };
}
