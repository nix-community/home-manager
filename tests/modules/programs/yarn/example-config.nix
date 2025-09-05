{
  programs.yarn = {
    enable = true;

    settings = {
      httpProxy = "http://proxy.example.org:3128";
      httpsProxy = "http://proxy.example.org:3128";
    };
  };

  nmt.script =
    let
      configPath = "home-files/.yarnrc.yml";
    in
    ''
      assertFileExists ${configPath}
      assertFileContent ${configPath} \
        ${./example-config.yml}
    '';
}
