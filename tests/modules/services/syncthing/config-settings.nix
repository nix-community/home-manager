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
      devices.test.id = "7CFNTQM-IMTJBHJ-3UWRDIU-ZGQJFR6-VCXZ3NB-XUH3KZO-N52ITXR-LAIYUAU";
      folders.test.path = "/home/hm-user/sync";
      defaults = {
        device.name = "Default Device";
        folder.path = "/tmp/syncthing-default";
        ignores.lines = [ "*.tmp" ];
      };
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
    assertFileContains "$updateScript" \
      "curl -X PATCH -d '{\"name\":\"Default Device\"}' 127.0.0.1:8384/rest/config/defaults/device"
    assertFileContains "$updateScript" \
      "curl -X PATCH -d '{\"path\":\"/tmp/syncthing-default\"}' 127.0.0.1:8384/rest/config/defaults/folder"
    assertFileContains "$updateScript" \
      "curl -X PUT -d '{\"lines\":[\"*.tmp\"]}' 127.0.0.1:8384/rest/config/defaults/ignores"

    for kind in device folder; do
      defaultsLine=$(grep -n "rest/config/defaults/$kind$" "$updateScript" | cut -d: -f1)
      objectLine=$(grep -n "curl --json @- -X POST .*rest/config/''${kind}s$" "$updateScript" | cut -d: -f1)
      test -n "$defaultsLine" && test -n "$objectLine"
      test "$defaultsLine" -lt "$objectLine" \
        || fail "Syncthing $kind defaults must be applied before creating objects"
    done

    if grep -Eq 'curl -X PUT .*rest/config/(gui|ldap|options)' "$(_abs "$updateScript")"; then
      fail "Syncthing settings should use partial updates"
    fi
  '';
}
