{
  config,
  pkgs,
  ...
}:
let
  environmentFile = pkgs.writeText "t3code-env" ''
    T3CODE_PORT=4567
  '';
  testT3code = pkgs.writeShellScriptBin "t3" ''
    [ "$T3CODE_PORT" = 4567 ] || exit 1
  '';
in
{
  programs.t3code = {
    enable = true;
    package = testT3code;

    server = {
      enable = true;
      environmentFile = "/run/secrets/t3code";
    };
  };

  nmt.script =
    if pkgs.stdenv.hostPlatform.isDarwin then
      let
        serviceLauncher = builtins.head config.launchd.agents.t3code.config.ProgramArguments;
      in
      ''
        serviceFile=LaunchAgents/org.nix-community.home.t3code.plist
        assertFileExists "$serviceFile"
        serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
        assertFileContent "$serviceFileNormalized" ${./server-environment-file.plist}

        launcherNormalized="$(normalizeStorePaths "${serviceLauncher}")"
        substitute ${./server-environment-file-launcher.sh} "$TMPDIR/launcher-expected.sh" \
          --replace-fail '@shell@' '${pkgs.runtimeShell}'
        launcherExpectedNormalized="$(normalizeStorePaths "$TMPDIR/launcher-expected.sh")"
        assertFileContent "$launcherNormalized" "$launcherExpectedNormalized"

        substitute "${serviceLauncher}" "$TMPDIR/t3code-launcher" \
          --replace-fail '/run/secrets/t3code' '${environmentFile}'
        ${pkgs.runtimeShell} "$TMPDIR/t3code-launcher" \
          || fail "t3code's launcher must export the environment file's variables to the server"

        substitute "${serviceLauncher}" "$TMPDIR/t3code-launcher-missing" \
          --replace-fail '/run/secrets/t3code' "$TMPDIR/missing"
        ! T3CODE_PORT=4567 ${pkgs.runtimeShell} "$TMPDIR/t3code-launcher-missing" 2>/dev/null \
          || fail "t3code's launcher must not start the server when the environment file fails to load"
      ''
    else
      ''
        serviceFile=home-files/.config/systemd/user/t3code.service
        assertFileExists "$serviceFile"
        serviceFileNormalized="$(normalizeStorePaths "$serviceFile")"
        assertFileContent "$serviceFileNormalized" ${./server-environment-file.service}
      '';
}
