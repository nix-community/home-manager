{
  pkgs,
  ...
}:
{
  programs.t3code = {
    enable = true;

    server = {
      enable = true;
      extraArgs = [
        "--host"
        "0.0.0.0"
        "--port"
        "3773"
      ];
    };
  };

  nmt.script =
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''
        serviceFile=LaunchAgents/org.nix-community.home.t3code.plist
        assertFileExists "$serviceFile"
        assertFileContent "$serviceFile" ${./server.plist}
      ''
    else
      ''
        serviceFile=home-files/.config/systemd/user/t3code.service
        assertFileExists "$serviceFile"
        assertFileContent "$serviceFile" ${./server.service}
      '';
}
