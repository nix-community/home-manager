{
  programs.moor = {
    enable = true;
    enableJujutsuIntegration = false;
  };

  programs.jujutsu = {
    enable = true;
    settings.user.name = "Home Manager";
  };

  nmt.script = ''
    assertFileContent home-files/.config/jj/config.toml ${builtins.toFile "expected" ''
      [user]
      name = "Home Manager"
    ''}
  '';
}
