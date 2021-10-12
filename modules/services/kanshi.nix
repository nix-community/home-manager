{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.kanshi;

  outputModule = types.submodule {
    options = {

      criteria = mkOption {
        type = types.str;
        description = ''
          The criteria can either be an output name, an output description or "*".
          The latter can be used to match any output.

          On
          <citerefentry>
            <refentrytitle>sway</refentrytitle>
            <manvolnum>1</manvolnum>
          </citerefentry>,
          output names and descriptions can be obtained via
          <literal>swaymsg -t get_outputs</literal>.
        '';
      };

      status = mkOption {
        type = types.nullOr (types.enum [ "enable" "disable" ]);
        default = null;
        description = ''
          Enables or disables the specified output.
        '';
      };

      mode = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "1920x1080@60Hz";
        description = ''
          &lt;width&gt;x&lt;height&gt;[@&lt;rate&gt;[Hz]]
          </para><para>
          Configures the specified output to use the specified mode.
          Modes are a combination of width and height (in pixels) and
          a refresh rate (in Hz) that your display can be configured to use.
        '';
      };

      position = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "1600,0";
        description = ''
          &lt;x&gt;,&lt;y&gt;
          </para><para>
          Places the output at the specified position in the global coordinates
          space.
        '';
      };

      scale = mkOption {
        type = types.nullOr types.float;
        default = null;
        example = 2;
        description = ''
          Scales the output by the specified scale factor.
        '';
      };

      transform = mkOption {
        type = types.nullOr (types.enum [
          "normal"
          "90"
          "180"
          "270"
          "flipped"
          "flipped-90"
          "flipped-180"
          "flipped-270"
        ]);
        default = null;
        description = ''
          Sets the output transform.
        '';
      };
    };
  };

  outputStr = { criteria, status, mode, position, scale, transform, ... }:
    ''output "${criteria}"'' + optionalString (status != null) " ${status}"
    + optionalString (mode != null) " mode ${mode}"
    + optionalString (position != null) " position ${position}"
    + optionalString (scale != null) " scale ${toString scale}"
    + optionalString (transform != null) " transform ${transform}";

  profileModule = types.submodule {
    options = {
      outputs = mkOption {
        type = types.listOf outputModule;
        default = [ ];
        description = ''
          Outputs configuration.
        '';
      };

      exec = mkOption {
        type = with types; coercedTo str singleton (listOf str);
        default = [ ];
        example =
          "[ \${pkg.sway}/bin/swaymsg workspace 1, move workspace to eDP-1 ]";
        description = ''
          Commands executed after the profile is succesfully applied.
          Note that if you provide multiple commands, they will be
          executed asynchronously with no guaranteed ordering.
        '';
      };
    };
  };

  profileStr = name:
    { outputs, exec, ... }: ''
      profile ${name} {
        ${
          concatStringsSep "\n  "
          (map outputStr outputs ++ map (cmd: "exec ${cmd}") exec)
        }
      }
    '';
in {

  meta.maintainers = [ maintainers.nurelin ];

  options.services.kanshi = {
    enable = mkEnableOption
      "kanshi, a Wayland daemon that automatically configures outputs";

    package = mkOption {
      type = types.package;
      default = pkgs.kanshi;
      defaultText = literalExpression "pkgs.kanshi";
      description = ''
        kanshi derivation to use.
      '';
    };

    profiles = mkOption {
      type = types.attrsOf profileModule;
      default = { };
      description = ''
        List of profiles.
      '';
      example = literalExpression ''
        undocked = {
          outputs = [
            {
              criteria = "eDP-1";
            }
          ];
        };
        docked = {
          outputs = [
            {
              criteria = "eDP-1";
            }
            {
              criteria = "Some Company ASDF 4242";
              transform = "90";
            }
          ];
        };
      '';
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = ''
        Extra configuration lines to append to the kanshi
        configuration file.
      '';
    };

    systemdTarget = mkOption {
      type = types.str;
      default = "sway-session.target";
      description = ''
        Systemd target to bind to.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.kanshi" pkgs
        lib.platforms.linux)
    ];

    xdg.configFile."kanshi/config".text = ''
      ${concatStringsSep "\n" (mapAttrsToList profileStr cfg.profiles)}
      ${cfg.extraConfig}
    '';

    systemd.user.services.kanshi = {
      Unit = {
        Description = "Dynamic output configuration";
        Documentation = "man:kanshi(1)";
        PartOf = cfg.systemdTarget;
        Requires = cfg.systemdTarget;
        After = cfg.systemdTarget;
      };

      Service = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/kanshi";
        Restart = "always";
      };

      Install = { WantedBy = [ cfg.systemdTarget ]; };
    };
  };
}
