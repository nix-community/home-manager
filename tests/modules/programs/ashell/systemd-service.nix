{ pkgs, ... }:

let
  ashellPackage = pkgs.runCommand "ashell-0.5.0" { } ''
    mkdir -p $out/bin
    echo '#!/bin/sh' > $out/bin/ashell
    chmod +x $out/bin/ashell
  '';
in
{
  programs.ashell = {
    enable = true;
    package = ashellPackage;
    settings = {
      modules = {
        left = [ "Workspaces" ];
      };
    };
    systemd = {
      enable = true;
      target = "hyprland-session.target";
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/ashell/config.toml
    assertFileExists home-files/.config/systemd/user/ashell.service
    # Check that the service file contains the expected content
    assertFileRegex home-files/.config/systemd/user/ashell.service "ExecStart=.*ashell-0.5.0.*/bin/ashell"
    assertFileRegex home-files/.config/systemd/user/ashell.service "WantedBy=hyprland-session.target"
    assertFileRegex home-files/.config/systemd/user/ashell.service "Description=ashell status bar"
  '';
}
