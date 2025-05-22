{
  config,
  pkgs,
  ...
}:

let
  hmPkgs = pkgs.extend (
    self: super: {
      sketchybar = config.lib.test.mkStubPackage {
        name = "sketchybar";
        buildScript = ''
          mkdir -p $out/bin
          touch $out/bin/sketchybar
          chmod 755 $out/bin/sketchybar
        '';
      };
      jq = config.lib.test.mkStubPackage { outPath = "/@jq@"; };
    }
  );
in
{
  programs.sketchybar = {
    enable = true;
    package = hmPkgs.sketchybar;
    configType = "bash";

    config = ''
      #!/usr/bin/env bash

      # Configure bar
      sketchybar --bar height=30 \
                      position=top \
                      padding_left=10 \
                      padding_right=10

      # Update the bar
      sketchybar --update
    '';

    # Enable the integrated service
    service = {
      enable = true;
      errorLogFile = "/home/hm-user/Library/Logs/sketchybar/sketchybar.err.log";
      outLogFile = "/home/hm-user/Library/Logs/sketchybar/sketchybar.out.log";
    };
  };

  # Change home directory for the test
  home.homeDirectory = "/home/hm-user";

  # Validate the generated config files
  nmt.script = ''
    # Verify config file exists
    assertFileExists home-files/.config/sketchybar/sketchybarrc

    # Verify service file exists and matches expected content
    serviceFile=LaunchAgents/org.nix-community.home.sketchybar.plist
    assertFileExists "$serviceFile"
    assertFileContent "$serviceFile" ${./sketchybar-service-expected.plist}
  '';
}
