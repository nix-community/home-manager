{
  config,
  lib,
  pkgs,
  ...
}:
{
  time = "2026-10-24T00:11:49+00:00";
  condition =
    pkgs.stdenv.hostPlatform.isDarwin
    && config.launchd.enable
    && lib.any (agent: agent.enable) (lib.attrValues config.launchd.agents);
  message = ''
    Home Manager launchd agents now default NIX_SSL_CERT_FILE to
    nix-darwin's selected CA bundle. Standalone agents prefer
    /etc/ssl/certs/ca-certificates.crt, falling back to cacert from Home
    Manager's Nixpkgs input only when that file is missing.

    Existing NIX_SSL_CERT_FILE or SSL_CERT_FILE values, including empty
    values, are preserved. System certificates are not modified.
  '';
}
