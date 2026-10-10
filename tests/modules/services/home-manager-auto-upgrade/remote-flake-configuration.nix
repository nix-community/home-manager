{
  home.stateVersion = "26.05";

  services.home-manager.autoUpgrade = {
    enable = true;
    frequency = "daily";
    useFlake = true;
    flakeUrl = "github:somebody/dotfiles";
  };

  nmt.script = ''
    serviceFile="home-files/.config/systemd/user/home-manager-auto-upgrade.service"
    assertFileExists "$serviceFile"
    assertFileRegex "$serviceFile" "FLAKE_URL=github:somebody/dotfiles"

    execFile="$(grep ExecStart= "$TESTED/$serviceFile" | cut -d= -f2-)"
    assertFileRegex "$execFile" "switch --flake \"\$FLAKE_URL\""
  '';
}
