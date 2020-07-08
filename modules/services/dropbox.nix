{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dropbox;
  baseDir = ".dropbox-hm";
  dropboxCmd = ''
    ${pkgs.coreutils}/bin/env -i HOME="$HOME" ${pkgs.dropbox-cli}/bin/dropbox'';
in {
  meta.maintainers = [ maintainers.eyjhb ];

  options = {
    services.dropbox = {
      enable = mkEnableOption "Dropbox daemon";

      path = mkOption {
        type = types.path;
        default = "${config.home.homeDirectory}/Dropbox";
        defaultText = "\${config.home.homeDirectory}/Dropbox";
        description = "Where to put the Dropbox directory.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [{
    home.packages = [ pkgs.dropbox-cli ];

    systemd.user.services.dropbox = {
      Unit = { Description = "Starting dropbox"; };

      Install = { WantedBy = [ "default.target" ]; };

      Service = {
        Environment = [ "HOME=${config.home.homeDirectory}/${baseDir}" ];

        Type = "forking";
        PIDFile =
          "${config.home.homeDirectory}/${baseDir}/.dropbox/dropbox.pid";

        Restart = "on-failure";
        PrivateTmp = true;
        ProtectSystem = "full";
        Nice = 10;

        ExecReload = "${pkgs.coreutils.out}/bin/kill -HUP $MAINPID";
        ExecStop = "${dropboxCmd} stop";
        ExecStart = let
          script = pkgs.writeScript "dropboxInit" ''
            #!/bin/sh
            if [ ! -f $HOME/.dropbox-dist/VERSION ]; then
              ${pkgs.coreutils}/bin/yes | ${pkgs.coreutils}/bin/env -i HOME="$HOME" ${pkgs.dropbox-cli}/bin/dropbox update
            fi

            ${dropboxCmd} start
          '';
        in "${script}";
      };
    };

    home.activation.dropbox = let dag = lib.hm.dag;
    in dag.entryAfter [ "writeBoundary" ] ''
      # ensure we have the dirs we need
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/${baseDir}/.dropbox
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/${baseDir}/.dropbox-dist
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p ${config.home.homeDirectory}/${baseDir}/Dropbox

      # symlink them as needed
      if [ ! -d ${config.home.homeDirectory}/.dropbox ]; then $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -s ${config.home.homeDirectory}/${baseDir}/.dropbox ${config.home.homeDirectory}/.dropbox; fi
      # if [ ! -d ${config.home.homeDirectory}/.dropbox-dist ]; then $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -s ${config.home.homeDirectory}/${baseDir}/.dropbox-dist ${config.home.homeDirectory}/.dropbox-dist; fi
      if [ ! -d ${cfg.path} ]; then $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln -s ${config.home.homeDirectory}/${baseDir}/Dropbox ${cfg.path}; fi
    '';
  }]);
}
