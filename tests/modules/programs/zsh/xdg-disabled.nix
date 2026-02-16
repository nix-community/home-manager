{
  config = {
    programs.zsh.enable = true;
    xdg.enable = false;
    home.stateVersion = "26.05";

    # With xdg.enable = false, dotDir should default to home directory regardless of state version

    nmt.script = ''
      assertFileExists home-files/.zshenv
      assertFileExists home-files/.zshrc

      # Should NOT exist in XDG location
      assertPathNotExists home-files/.config/zsh

      # Verify ZDOTDIR is NOT exported (or points to home if it is, but usually it isn't if dotDir is home)
      assertFileNotRegex home-files/.zshenv "export ZDOTDIR="
    '';
  };
}
