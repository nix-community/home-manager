{
  config,
  lib,
  pkgs,
  ...
}:

{
  meta.maintainers = [ lib.maintainers.somasis ];

  options = {
    services.sctd = {
      enable = lib.mkEnableOption "sctd";

      package = lib.mkPackageOption pkgs "sct" { };

      baseTemperature = lib.mkOption {
        type = lib.types.ints.between 2500 9000;
        default = 4500;
        description = ''
          The base color temperature used by sctd, which should be between 2500 and 9000.
          See
          {manpage}`sctd(1)`
          for more details.
        '';
      };
    };
  };

  config = lib.mkIf config.services.sctd.enable {
    assertions = [ (lib.hm.assertions.assertPlatform "services.sctd" pkgs lib.platforms.linux) ];

    systemd.user.services.sctd = {
      Unit = {
        Description = "Dynamically adjust the screen color temperature twice every minute";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service = {
        ExecStart = "${config.services.sctd.package}/bin/sctd ${toString config.services.sctd.baseTemperature}";
        ExecStopPost = "${config.services.sctd.package}/bin/sct";
        Restart = "on-abnormal";
        SuccessExitStatus = 1;

        Environment =
          let
            # HACK: Remove duplicate messages in the journal; `sctd` calls
            #       both `logger -s` (which outputs the message to stderr)
            #       *and* outputs to stderr itself. We can at least silence
            #       `logger`'s output without hiding sctd's own stderr.
            logger = pkgs.writeShellScriptBin "logger" ''
              exec 2>/dev/null
              exec ${pkgs.util-linux}/bin/logger "$@"
            '';
          in
          [
            "PATH=${
              lib.makeBinPath [
                pkgs.bash
                pkgs.coreutils
                pkgs.gnused
                pkgs.which
                config.services.sctd.package
                logger
              ]
            }"
          ];
      };
    };
  };
}
