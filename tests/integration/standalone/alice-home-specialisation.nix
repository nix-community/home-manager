{ lib, ... }:

{
  home.username = "alice";
  home.homeDirectory = "/home/alice";
  home.stateVersion = "25.05";
  home.file.test.text = "test";
  home.file.base-only.text = "base";
  home.sessionVariables.EDITOR = "emacs";
  programs.bash.enable = true;
  programs.home-manager.enable = true;

  specialisation.pueue.configuration = {
    # Enable a light-weight systemd service.
    services.pueue.enable = true;

    # Change a file that has a hook and drop another, for the files-only
    # activation. The hook ends in a failed condition, which an activation
    # continues past.
    home.file.test = {
      text = lib.mkForce "pueue";
      onChange = ''
        echo changed >> "$HOME/test-changes"
        [[ -e $HOME/no-such-file ]] && echo unreachable
      '';
    };
    home.file.base-only.enable = false;
  };
}
