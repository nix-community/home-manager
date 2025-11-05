{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.systemd.user.tmpfiles;

in
{
  meta.maintainers = with lib.maintainers; [
    bmrips
    dawidsowa
  ];

  options.systemd.user.tmpfiles.rules = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
    example = [ "L /home/user/Documents - - - - /mnt/data/Documents" ];
    description = ''
      Rules for creating and cleaning up temporary files
      automatically. See
      {manpage}`tmpfiles.d(5)`
      for the exact format.
    '';
  };

  config = lib.mkIf (cfg.rules != [ ]) {
    assertions = [
      (lib.hm.assertions.assertPlatform "systemd.user.tmpfiles" pkgs lib.platforms.linux)
    ];

    xdg.configFile = {
      "user-tmpfiles.d/home-manager.conf" = {
        text = ''
          # This file is created automatically and should not be modified.
          # Please change the option ‘systemd.user.tmpfiles.rules’ instead.
          ${lib.concatStringsSep "\n" cfg.rules}
        '';
        onChange = ''
          run ${pkgs.systemd}/bin/systemd-tmpfiles --user --remove --create ''${DRY_RUN:+--dry-run}
        '';
      };
      "systemd/user/basic.target.wants/systemd-tmpfiles-setup.service".source =
        "${pkgs.systemd}/example/systemd/user/systemd-tmpfiles-setup.service";
      "systemd/user/systemd-tmpfiles-setup.service".source =
        "${pkgs.systemd}/example/systemd/user/systemd-tmpfiles-setup.service";
      "systemd/user/timers.target.wants/systemd-tmpfiles-clean.timer".source =
        "${pkgs.systemd}/example/systemd/user/systemd-tmpfiles-clean.timer";
      "systemd/user/systemd-tmpfiles-clean.service".source =
        "${pkgs.systemd}/example/systemd/user/systemd-tmpfiles-clean.service";
    };
  };
}
