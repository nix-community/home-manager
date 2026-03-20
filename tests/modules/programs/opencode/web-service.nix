{
  pkgs,
  ...
}:
{
  programs.opencode = {
    enable = true;

    web = {
      enable = true;
      extraArgs = [
        "--hostname"
        "0.0.0.0"
        "--port"
        "4096"
        "--mdns"
        "--cors"
        "https://example.com"
        "--cors"
        "http://localhost:3000"
        "--print-logs"
        "--log-level"
        "DEBUG"
      ];
    };
  };

  nmt.script =
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''
        serviceFile=LaunchAgents/org.nix-community.home.opencode-web.plist
        assertFileExists "$serviceFile"
        assertFileContent "$serviceFile" ${./web-service.plist}
      ''
    else
      ''
        serviceFile=home-files/.config/systemd/user/opencode-web.service
        assertFileExists "$serviceFile"
        assertFileContent "$serviceFile" ${./web-service.service}
      '';
}
