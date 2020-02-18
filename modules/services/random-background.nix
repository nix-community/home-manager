{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.random-background;

  flags = lib.concatStringsSep " "
    ([ "--bg-${cfg.display}" "--no-fehbg" "--randomize" ]
      ++ lib.optional (!cfg.enableXinerama) "--no-xinerama");

in {
  meta.maintainers = [ maintainers.rycee ];

  options = {
    services.random-background = {
      enable = mkEnableOption "" // {
        description = ''
          Whether to enable random desktop background.
          </para><para>
          Note, if you are using NixOS and have set up a custom
          desktop manager session for Home Manager, then the session
          configuration must have the <option>bgSupport</option>
          option set to <literal>true</literal> or the background
          image set by this module may be overwritten.
        '';
      };

      imageDirectory = mkOption {
        type = types.str;
        example = "%h/backgrounds";
        description = ''
          The directory of images from which a background should be
          chosen. Should be formatted in a way understood by systemd,
          e.g., '%h' is the home directory.
        '';
      };

      display = mkOption {
        type = types.enum [ "center" "fill" "max" "scale" "tile" ];
        default = "fill";
        description = "Display background images according to this option.";
      };

      interval = mkOption {
        default = null;
        type = types.nullOr types.str;
        example = "1h";
        description = ''
          The duration between changing background image, set to null
          to only set background when logging in. Should be formatted
          as a duration understood by systemd.
        '';
      };

      enableXinerama = mkOption {
        default = true;
        type = types.bool;
        description = ''
          Will place a separate image per screen when enabled,
          otherwise a single image will be stretched across all
          screens.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge ([
    {
      systemd.user.services.random-background = {
        Unit = {
          Description = "Set random desktop background using feh";
          After = [ "graphical-session-pre.target" ];
          PartOf = [ "graphical-session.target" ];
        };

        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.feh}/bin/feh ${flags} ${cfg.imageDirectory}";
          IOSchedulingClass = "idle";
        };

        Install = { WantedBy = [ "graphical-session.target" ]; };
      };
    }
    (mkIf (cfg.interval != null) {
      systemd.user.timers.random-background = {
        Unit = { Description = "Set random desktop background using feh"; };

        Timer = { OnUnitActiveSec = cfg.interval; };

        Install = { WantedBy = [ "timers.target" ]; };
      };
    })
  ]));
}
