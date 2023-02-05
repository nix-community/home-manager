{ ... }:

{
  programs = {
    zsh.enable = true;

    oh-my-posh = {
      enable = true;
      useTheme = "jandedobbeleer";
    };
  };

  test.stubs = {
    oh-my-posh = { };
    zsh = { };
  };

  nmt.script = ''
    assertFileExists home-files/.zshrc
    assertFileContains \
      home-files/.zshrc \
      '/bin/oh-my-posh init zsh --config'
  '';
}
