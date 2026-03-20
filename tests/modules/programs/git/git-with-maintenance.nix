{ lib, pkgs, ... }:

lib.mkMerge [
  {
    programs.git = {
      enable = true;
      maintenance.enable = true;
    };
  }

  (lib.mkIf pkgs.stdenv.isDarwin {
    nmt.script = ''
      serviceFile=LaunchAgents/org.nix-community.home.git-maintenance-hourly.plist
      assertFileExists "$serviceFile"
      assertFileContent "$serviceFile" ${./expected-agent-hourly.plist}

      serviceFile=LaunchAgents/org.nix-community.home.git-maintenance-daily.plist
      assertFileExists "$serviceFile"
      assertFileContent "$serviceFile" ${./expected-agent-daily.plist}

      serviceFile=LaunchAgents/org.nix-community.home.git-maintenance-weekly.plist
      assertFileExists "$serviceFile"
      assertFileContent "$serviceFile" ${./expected-agent-weekly.plist}
    '';
  })
]
