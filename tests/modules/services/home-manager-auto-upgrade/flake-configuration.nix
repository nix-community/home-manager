{
  services.home-manager.autoUpgrade = {
    enable = true;
    frequency = "daily";
    useFlake = true;
    flakeDir = "/tmp/my-flake";
  };

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/home-manager-auto-upgrade.service"
    assertFileExists "$serviceFile"
    assertFileRegex "$serviceFile" "FLAKE_DIR=/tmp/my-flake"

    scriptPath=$(grep -oP 'ExecStart=\K.+' "$TESTED/$serviceFile")
    assertFileRegex "$scriptPath" "nix flake update"
  '';
}
