{
  pkgs,
  ...
}:
{
  programs.opencode = {
    enable = true;

    web = {
      enable = true;
      environmentFile = "/run/secrets/opencode";
    };
  };

  nmt.script =
    if pkgs.stdenv.hostPlatform.isDarwin then
      ''
        serviceFile=LaunchAgents/org.nix-community.home.opencode-web.plist
        assertFileExists "$serviceFile"
        serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
        assertFileContent "$serviceFileNormalized" ${./web-service-environment-file.plist}
      ''
    else
      ''
        serviceFile=home-files/.config/systemd/user/opencode-web.service
        assertFileExists "$serviceFile"
        assertFileContent "$serviceFile" ${./web-service-environment-file.service}
      '';
}
