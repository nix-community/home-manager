{
  programs.mitmproxy = {
    enable = true;
    settings = {
      listen_port = 8081;
      ssl_insecure = true;
      anticache = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.mitmproxy/config.yaml
    assertFileContent home-files/.mitmproxy/config.yaml \
      ${./expected-config.yaml}
  '';
}
