{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.services.dropbox;
  baseDir = ".dropbox-hm";
  dropboxCmd = "${lib.getExe' cfg.package "dropbox"}";
  homeBaseDir = "${config.home.homeDirectory}/${baseDir}";

in
{
  meta.maintainers = [ lib.maintainers.eyjhb ];

  options = {
    services.dropbox = {
      enable = lib.mkEnableOption "Dropbox daemon";

      package = lib.mkPackageOption pkgs "dropbox-cli" { };

      path = lib.mkOption {
        type = lib.types.path;
        default = "${config.home.homeDirectory}/Dropbox";
        defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/Dropbox"'';
        apply = toString; # Prevent copies to Nix store.
        description = "Where to put the Dropbox directory.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.dropbox" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    systemd.user.services.dropbox = {
      Unit = {
        Description = "dropbox";
      };

      Install = {
        WantedBy = [ "default.target" ];
      };

      Service = {
        Environment = [
          "HOME=${homeBaseDir}"
          "DISPLAY="
        ];

        Type = "forking";
        PIDFile = "${homeBaseDir}/.dropbox/dropbox.pid";

        Restart = "on-failure";
        PrivateTmp = true;
        ProtectSystem = "full";
        Nice = 10;

        ExecReload = "${pkgs.coreutils}/bin/kill -HUP $MAINPID";
        ExecStop = "${dropboxCmd} stop";
        ExecStart = toString (
          pkgs.writeShellScript "dropbox-start" ''
            # ensure we have the dirs we need
            run ${pkgs.coreutils}/bin/mkdir $VERBOSE_ARG -p \
              ${homeBaseDir}/{.dropbox,.dropbox-dist,Dropbox}

            # symlink them as needed
            if [[ ! -d ${config.home.homeDirectory}/.dropbox ]]; then
              run ${pkgs.coreutils}/bin/ln $VERBOSE_ARG -s \
                ${homeBaseDir}/.dropbox ${config.home.homeDirectory}/.dropbox
            fi

            if [[ ! -d ${lib.escapeShellArg cfg.path} ]]; then
              run ${pkgs.coreutils}/bin/ln $VERBOSE_ARG -s \
                ${homeBaseDir}/Dropbox ${lib.escapeShellArg cfg.path}
            fi

            # get the dropbox bins if needed
            if [[ ! -f $HOME/.dropbox-dist/VERSION ]]; then
              ${pkgs.coreutils}/bin/yes | ${dropboxCmd} update
            fi

            ${dropboxCmd} start
          ''
        );
      };
    };
  };
}
