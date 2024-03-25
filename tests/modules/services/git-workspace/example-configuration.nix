{ config, lib, ... }:
let cfg = config.services.git-workspace;
in {
  services.git-workspace = {
    enable = true;
    frequency = "04:00:00";
    # Never put secrets in files which are copied into the store by Nix
    environmentFile = ./git-workspace-tokens;
    workspaces = let projectsDir = "${config.home.homeDirectory}/projects";
    in {
      edolstra = {
        provider = [{
          provider = "github";
          name = "edolstra";
          path = projectsDir;
          skips_forks = false;
        }];
      };
      nix = {
        provider = [
          {
            provider = "github";
            name = "nixos";
            path = projectsDir;
            skip_forks = false;
          }
          {
            provider = "github";
            name = "nix-community";
            path = projectsDir;
            skip_forks = false;
          }
        ];
      };
    };
  };
  nmt.script = lib.concatMapStrings (workspaceName: ''
    local serviceFile=home-files/.config/systemd/user/git-workspace-${workspaceName}-update.service
    local timerFile=home-files/.config/systemd/user/git-workspace-${workspaceName}-update.timer
    local configFile=home-files/.config/git-workspace/${workspaceName}/workspace.toml

    assertFileExists $serviceFile
    assertFileExists $timerFile
    assertFileExists $configFIle
  '') (builtins.attrNames cfg.workspaces);
}
