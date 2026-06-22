{
  services.syncthing = {
    enable = true;
    guiAddress = "127.0.0.1:8385";
  };

  nmt.script = ''
    serviceFile=home-files/.config/systemd/user/syncthing-init.service
    assertFileExists "$serviceFile"
    assertFileExists home-files/.config/systemd/user/default.target.wants/syncthing-init.service
    assertFileContains "$serviceFile" "ExecStart="

    updateScript=$(grep -o '/nix/store/[^ ]*-merge-syncthing-config' "$TESTED/$serviceFile")
    assertFileContains "$updateScript" "127.0.0.1:8385/rest/config/gui"
    assertFileContains "$updateScript" 'syncthing_config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}/syncthing"'
    assertFileContains "$updateScript" 'syncthing_dir="$syncthing_config_dir"'
  '';
}
