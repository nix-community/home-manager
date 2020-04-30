{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.systemd.user.tmpfiles;

in {
  meta.maintainers = [ maintainers.dawidsowa ];

  options.systemd.user.tmpfiles.rules = mkOption {
    type = types.listOf types.str;
    default = [ ];
    example = [ "L /home/user/Documents - - - - /mnt/data/Documents" ];
    description = ''
      Rules for creating and cleaning up temporary files
      automatically. See
      <citerefentry>
        <refentrytitle>tmpfiles.d</refentrytitle>
        <manvolnum>5</manvolnum>
      </citerefentry>
      for the exact format.
    '';
  };

  config = mkIf (cfg.rules != [ ]) {
    xdg = {
      dataFile."user-tmpfiles.d/home-manager.conf" = {
        text = ''
          # This file is created automatically and should not be modified.
          # Please change the option ‘systemd.user.tmpfiles.rules’ instead.
          ${concatStringsSep "\n" cfg.rules}
        '';
        onChange = "${pkgs.systemd}/bin/systemd-tmpfiles --user --create";
      };
      configFile = {
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
  };
}
