{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.autoUpgrade; in

{

  options = {

    services.autoUpgrade = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to periodically upgrade NixOS to the latest
          version. If enabled, a systemd timer will run
          <literal>nixos-rebuild switch --upgrade</literal> once a
          day.
        '';
      };

      # channel = mkOption {
      #   type = types.nullOr types.str;
      #   default = null;
      #   example = "https://nixos.org/channels/nixos-14.12-small";
      #   description = ''
      #     The URI of the NixOS channel to use for automatic
      #     upgrades. By default, this is the channel set using
      #     <command>nix-channel</command> (run <literal>nix-channel
      #     --list</literal> to see the current value).
      #   '';
      # };

      flags = mkOption {
        type = types.listOf types.str;
        default = [];
        example = [ "-I" "stuff=/home/alice/nixos-stuff" "--option" "extra-binary-caches" "http://my-cache.example.org/" ];
        description = ''
          Any additional flags passed to <command>nixos-rebuild</command>.
        '';
      };

      frequency = mkOption {
        type = types.str;
        default = "*:0/5";
        description = ''
          How often to update home-manager
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {

    services.autoUpgrade.flags =
      # "--no-build-output"
      [  ]
      # ++ (if cfg.channel == null
      #     then [ "--upgrade" ]
      #     else [ "-I" "nixpkgs=${cfg.channel}/nixexprs.tar.xz" ]);
      ;


    systemd.user.services.home-manager-update = {
      Unit = {
        Description = "Home-manager update";
      };

      Service = {
        Type = "oneshot";
        # always forbidden for oneshot
        Restart = "on-abort";
        RestartSec = 12;

        ExecStart = let
            home-manager = "${pkgs.home-manager}/bin/home-manager";
          in ''
              ${home-manager} switch ${toString cfg.flags}
          '';
      };
    };

    systemd.user.timers.autoUpgrade = {
      Unit = { Description = "Home-manager periodic update"; };
      Timer = {
        Unit = "home-manager-update.service";
        OnCalendar = cfg.frequency;
      };
      Install = { WantedBy = [ "timers.target" ]; };
    };
  };
}
