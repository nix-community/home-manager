{
  programs.mitmproxy.enable = true;

  nmt.script = ''
    assertPathNotExists home-files/.mitmproxy/config.yaml
  '';
}
