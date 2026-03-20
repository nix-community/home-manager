{
  programs.aperture = {
    enable = true;
    settings = {
      listenaddr = "localhost:8081";
      staticroot = "./static";
      servestatic = false;
      debuglevel = "debug";
      autocert = false;
      servername = "aperture.example.com";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.aperture/aperture.yaml
    assertFileContent home-files/.aperture/aperture.yaml \
      ${./aperture.yaml}
  '';
}
