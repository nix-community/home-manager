{ pkgs, ... }:
let
  serviceFile =
    if pkgs.stdenv.hostPlatform.isLinux then
      "home-files/.config/systemd/user/syncthing-init.service"
    else
      "LaunchAgents/org.nix-community.home.syncthing-init.plist";
in
{
  services.syncthing = {
    enable = true;
    settings.gui.theme = "black";
  };

  nmt.script = ''
    serviceFile=${serviceFile}
    assertFileExists "$serviceFile"

    updateScript=$(grep -o '/nix/store/[^ <]*-merge-syncthing-config' "$TESTED/$serviceFile")
    assertFileContains "$updateScript" \
      "curl -X PATCH -d '{\"theme\":\"black\"}' 127.0.0.1:8384/rest/config/gui"

    if grep -qF "curl -X PUT" "$(_abs "$updateScript")"; then
      fail "Syncthing settings should use partial updates"
    fi
  '';
}
