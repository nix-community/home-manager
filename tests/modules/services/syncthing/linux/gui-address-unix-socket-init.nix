{
  services.syncthing = {
    enable = true;
    guiAddress = "/tmp/syncthing.sock";
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/syncthing-init.service
    assertFileExists "$serviceFile"
    assertFileContains "$serviceFile" "ExecStart="

    updateScript=$(grep -o '/nix/store/[^ ]*-merge-syncthing-config' "$TESTED/$serviceFile")
    # A unix-socket guiAddress must use a `localhost` placeholder authority. A
    # bare-dot host (`http://.`) is rejected by curl >= 8.21 as "Bad hostname".
    assertFileContains "$updateScript" "/tmp/syncthing.sock http://localhost/rest/config/gui"
  '';
}
