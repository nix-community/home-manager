{
  programs.yarn = {
    settings = {
      httpProxy = "http://proxy.example.org:3128";
      httpsProxy = "http://proxy.example.org:3128";
    };
  };

  nmt.script = ''
    assertPathNotExists home-files/.yarnrc.yml
  '';
}
