{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.grobi;

  eitherStrBoolIntList = with types;
    either str (either bool (either int (listOf str)));

in {
  meta.maintainers = [ maintainers.mbrgm ];

  options = {
    services.grobi = {
      enable = mkEnableOption "the grobi display setup daemon";

      executeAfter = mkOption {
        type = with types; listOf str;
        default = [ ];
        example = [ "setxkbmap dvorak" ];
        description = ''
          Commands to be run after an output configuration was
          changed. The Nix value declared here will be translated to
          JSON and written to the <option>execute_after</option> key
          in <filename>~/.config/grobi.conf</filename>.
        '';
      };

      rules = mkOption {
        type = with types; listOf (attrsOf eitherStrBoolIntList);
        default = [ ];
        example = literalExpression ''
          [
            {
              name = "Home";
              outputs_connected = [ "DP-2" ];
              configure_single = "DP-2";
              primary = true;
              atomic = true;
              execute_after = [
                "${pkgs.xorg.xrandr}/bin/xrandr --dpi 96"
                "${pkgs.xmonad-with-packages}/bin/xmonad --restart";
              ];
            }
            {
              name = "Mobile";
              outputs_disconnected = [ "DP-2" ];
              configure_single = "eDP-1";
              primary = true;
              atomic = true;
              execute_after = [
                "${pkgs.xorg.xrandr}/bin/xrandr --dpi 120"
                "${pkgs.xmonad-with-packages}/bin/xmonad --restart";
              ];
            }
          ]
        '';
        description = ''
          These are the rules grobi tries to match to the current
          output configuration. The rules are evaluated top to bottom,
          the first matching rule is applied and processing stops. See
          <link xlink:href="https://github.com/fd0/grobi/blob/master/doc/grobi.conf"/>
          for more information. The Nix value declared here will be
          translated to JSON and written to the <option>rules</option>
          key in <filename>~/.config/grobi.conf</filename>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.grobi" pkgs
        lib.platforms.linux)
    ];

    systemd.user.services.grobi = {
      Unit = {
        Description = "grobi display auto config daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "simple";
        ExecStart = "${pkgs.grobi}/bin/grobi watch -v";
        Restart = "always";
        RestartSec = "2s";
        Environment = "PATH=${pkgs.xorg.xrandr}/bin:${pkgs.bash}/bin";
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };
    };

    xdg.configFile."grobi.conf".text = builtins.toJSON {
      execute_after = cfg.executeAfter;
      rules = cfg.rules;
    };
  };
}
