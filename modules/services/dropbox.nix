{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.dropbox;
  baseDir = ".dropbox-hm";
  dropboxCmd = ''
    ${pkgs.coreutils}/bin/env -i HOME="$HOME" ${pkgs.dropbox-cli}/bin/dropbox'';
  homeBaseDir = "${config.home.homeDirectory}/${baseDir}";
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

  config = mkIf cfg.enable {
    home.packages = [ pkgs.dropbox-cli ];

    systemd.user.services.dropbox = {
      Unit = { Description = "Starting dropbox"; };

      Install = { WantedBy = [ "default.target" ]; };

      Service = {
        Environment = [ "HOME=${homeBaseDir}" ];

        Type = "forking";
        PIDFile = "${homeBaseDir}/.dropbox/dropbox.pid";

        Restart = "on-failure";
        PrivateTmp = true;
        ProtectSystem = "full";
        Nice = 10;

        ExecReload = "${pkgs.coreutils.out}/bin/kill -HUP $MAINPID";
        ExecStop = "${dropboxCmd} stop";
        ExecStart = let
          script = pkgs.writeShellScript "dropboxInit" ''
            if [[ ! -f $HOME/.dropbox-dist/VERSION ]]; then
              ${pkgs.coreutils}/bin/yes | ${dropboxCmd} update
            fi

            ${dropboxCmd} start
          '';
        in "${script}";
      };
    };

    home.activation.dropbox = hm.dag.entryAfter [ "writeBoundary" ] ''
      # ensure we have the dirs we need
      $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir $VERBOSE_ARG -p ${homeBaseDir}{config.home.homeDirectory}/${baseDir}/{.dropbox,.dropbox-dist,Dropbox}

      # symlink them as needed
      if [[ ! -d ${config.home.homeDirectory}/.dropbox ]]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln $VERBOSE_ARG -s ${homeBaseDir}/.dropbox ${config.home.homeDirectory}/.dropbox
      fi
      if [[ ! -d ${escapeShellArg cfg.path} ]]; then
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/ln $VERBOSE_ARG -s ${homeBaseDir}/Dropbox ${
          escapeShellArg cfg.path
        }
      fi
    '';
  };
}
