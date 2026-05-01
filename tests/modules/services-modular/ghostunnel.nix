{ pkgs, ... }:
{
  home.services.tunnel = {
    imports = [ pkgs.ghostunnel.passthru.services.default ];
    ghostunnel = {
      listen = "127.0.0.1:8443";
      target = "127.0.0.1:8080";
      cert = "/run/secrets/cert.pem";
      key = "/run/secrets/key.pem";
      allowAll = true;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/systemd/user/tunnel.service
    assertFileContains home-files/.config/systemd/user/tunnel.service '/bin/ghostunnel'
    assertFileContains home-files/.config/systemd/user/tunnel.service 'allow-all'
    assertFileContains home-files/.config/systemd/user/tunnel.service 'LoadCredential=cert:/run/secrets/cert.pem'
  '';
}
