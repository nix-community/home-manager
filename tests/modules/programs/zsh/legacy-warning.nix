{
  config = {
    programs.zsh.enable = true;
    xdg.enable = true;

    # We use 25.05 to trigger the legacy warning (since < 26.05)
    # AND to bypass the global fix in tests/default.nix (which checks for 18.09)
    home.stateVersion = "25.05";

    nmt.script = ''
      assertFileExists home-files/.zshrc

      # Verify that the warning is generated
      # We check the evaluation output for the warning message
      assertPathNotExists home-files/.config/zsh
    '';

    test.asserts.warnings.expected = [
      ''
        The default value of `programs.zsh.dotDir` will change in future versions.
        You are currently using the legacy default (home directory) because `home.stateVersion` is less than "26.05".
        To silence this warning and lock in the current behavior, set:
          programs.zsh.dotDir = config.home.homeDirectory;
        To adopt the new behavior (XDG config directory), set:
          programs.zsh.dotDir = "''${config.xdg.configHome}/zsh";
      ''
    ];
  };
}
