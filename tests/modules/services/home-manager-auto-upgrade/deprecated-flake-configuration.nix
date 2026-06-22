{
  home.stateVersion = "25.11";

  services.home-manager.autoUpgrade = {
    enable = true;
    frequency = "daily";
    useFlake = true;
    flakeDir = "/tmp/my-flake";
  };

  test.asserts.warnings.expected = [
    ''
      The default value of `services.home-manager.autoUpgrade.preSwitchCommands` has changed from `[
        "nix flake update"
      ]` to `[ ]`.
      You are currently using the legacy default (`[
        "nix flake update"
      ]`) because `home.stateVersion` is less than "26.05".
      To silence this warning and keep legacy behavior, set:
        services.home-manager.autoUpgrade.preSwitchCommands = [
        "nix flake update"
      ];
      To adopt the new default behavior, set:
        services.home-manager.autoUpgrade.preSwitchCommands = [ ];
    ''
  ];

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/home-manager-auto-upgrade.service"
    assertFileExists "$serviceFile"
    assertFileRegex "$serviceFile" "FLAKE_DIR=/tmp/my-flake"

    scriptPath=$(grep -oP 'ExecStart=\K.+' "$TESTED/$serviceFile")
    assertFileRegex "$scriptPath" "nix flake update"
  '';
}
