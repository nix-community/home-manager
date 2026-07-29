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
    settings = {
      gui.theme = "black";
      ldap.address = "ldap://localhost";
      options.localAnnounceEnabled = false;
    };
  };

  nmt.script = ''
    serviceFile=${serviceFile}
    assertFileExists "$serviceFile"

    updateScript=$(grep -o '/nix/store/[^ <]*-merge-syncthing-config' "$TESTED/$serviceFile" | head -n 1)
    assertFileContains "$updateScript" \
      "curl -X PATCH -d '{\"theme\":\"black\"}' 127.0.0.1:8384/rest/config/gui"
    assertFileContains "$updateScript" \
      "curl -X PATCH -d '{\"address\":\"ldap://localhost\"}' 127.0.0.1:8384/rest/config/ldap"
    assertFileContains "$updateScript" \
      "curl -X PATCH -d '{\"localAnnounceEnabled\":false}' 127.0.0.1:8384/rest/config/options"
    if grep -Eq 'curl -X PUT .*rest/config/(gui|ldap|options)' "$(_abs "$updateScript")"; then
      fail "Syncthing settings should use partial updates"
    fi
  '';
}
