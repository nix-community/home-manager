{
  config = {
    programs.zsh.enable = true;
    home.stateVersion = "26.05";
    xdg.enable = true;

    # With xdg.enable = true and new state version, dotDir should default to XDG config home

    nmt.script = ''
      assertFileExists home-files/.config/zsh/.zshenv
      assertFileExists home-files/.config/zsh/.zshrc

      # Verify global .zshenv points to the XDG location
      assertFileExists home-files/.zshenv
      assertFileRegex home-files/.zshenv "source /home/hm-user/.config/zsh/.zshenv"

      # Verify ZDOTDIR is exported in the inner .zshenv
      assertFileRegex home-files/.config/zsh/.zshenv "export ZDOTDIR=\"/home/hm-user/.config/zsh\""
    '';
  };
}
