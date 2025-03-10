{
  programs = {
    bash.enable = true;

    oh-my-posh = {
      enable = true;
      useTheme = "jandedobbeleer";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      '/bin/oh-my-posh init bash --config'
  '';
}
