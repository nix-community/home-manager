# Smoke test that an upstream system-shape portable service module drops in
# unchanged. The generated unit intentionally contains system-oriented
# directives (`AmbientCapabilities`, `DynamicUser`) inherited from the upstream
# ghostunnel module; user systemd silently ignores the ones it cannot honour.
# `WantedBy=multi-user.target` is normalized to `default.target` by the
# translator. For a service meant to run as a user see `php-fpm.nix`.
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
    assertFileContent home-files/.config/systemd/user/tunnel.service ${./tunnel.service}
  '';
}
