{
  config,
  lib,
  pkgs,
  ...
}:
let
  profileHelper = pkgs.writeShellScriptBin "profile-helper" "";
  extraHelper = pkgs.writeShellScriptBin "extra-helper" "";
  inheritedHelper = pkgs.writeShellScriptBin "inherited-helper" "";
  testOpencode = pkgs.writeShellScriptBin "opencode" ''
    command -v profile-helper >/dev/null || exit 1
    command -v extra-helper >/dev/null || exit 1
    command -v inherited-helper >/dev/null || exit 1
  '';
  serviceLauncher =
    if pkgs.stdenv.hostPlatform.isDarwin then
      builtins.head config.launchd.agents.opencode-web.config.ProgramArguments
    else
      builtins.head config.systemd.user.services.opencode-web.Service.ExecStart;
in
{
  programs.opencode = {
    enable = true;
    package = testOpencode;
    extraPackages = [ extraHelper ];

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
    (
      if pkgs.stdenv.hostPlatform.isDarwin then
        ''
          serviceFile=LaunchAgents/org.nix-community.home.opencode-web.plist
          assertFileExists "$serviceFile"
          serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
          assertFileContent "$serviceFileNormalized" ${./web-service.plist}
        ''
      else
        ''
          serviceFile=home-files/.config/systemd/user/opencode-web.service
          assertFileExists "$serviceFile"
          serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
          assertFileContent "$serviceFileNormalized" ${./web-service.service}
        ''
    )
    + ''
      launcherNormalized="$(normalizeStorePaths "${serviceLauncher}")"
      substitute ${./web-service-launcher.sh} "$TMPDIR/launcher-expected.sh" \
        --replace-fail '@shell@' '${pkgs.runtimeShell}'
      launcherExpectedNormalized="$(normalizeStorePaths "$TMPDIR/launcher-expected.sh")"
      assertFileContent "$launcherNormalized" "$launcherExpectedNormalized"

      substitute "${serviceLauncher}" "$TMPDIR/opencode-web-launcher" \
        --replace-fail '${config.home.profileDirectory}/bin' '${lib.makeBinPath [ profileHelper ]}'
      PATH=${lib.makeBinPath [ inheritedHelper ]} ${pkgs.runtimeShell} "$TMPDIR/opencode-web-launcher" \
        || fail "OpenCode's launcher must provide profile and extra packages while preserving PATH"
    '';
}
