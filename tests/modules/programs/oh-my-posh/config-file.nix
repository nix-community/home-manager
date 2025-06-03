{
  programs = {
    bash.enable = true;

    oh-my-posh = {
      enable = true;
      configFile = "foo/bar/baz.yaml";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      '/bin/oh-my-posh init bash --config foo/bar/baz.yaml'
  '';
}
