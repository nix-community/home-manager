{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.kanshi;

  directivesTag = types.attrTag {
    profile = mkOption {
      type = profileModule;
      description = ''
        profile attribute set.
      '';
    };
    output = mkOption {
      type = outputModule;
      description = ''
        output attribute set.
      '';
    };
    include = mkOption {
      type = types.str;
      description = ''
        Include as another file from _path_.
        Expands shell syntax (see *wordexp*(3) for details).
      '';
    };
  };

  tagToStr = x:
    if x ? profile then
      profileStr x.profile
    else if x ? output then
      outputStr x.output
    else if x ? include then
      ''include "${x.include}"''
    else
      throw "Unknown tags ${attrNames x}";

  directivesStr = ''
    ${concatStringsSep "\n" (map tagToStr cfg.settings)}
  '';

  oldDirectivesStr = ''
    ${concatStringsSep "\n"
    (mapAttrsToList (n: v: profileStr (v // { name = n; })) cfg.profiles)}
    ${cfg.extraConfig}
  '';

  outputModule = types.submodule {
    options = {

      criteria = mkOption {
        type = types.str;
        description = ''
          The criteria can either be an output name, an output description or "*".
          The latter can be used to match any output.

          On
          {manpage}`sway(1)`,
          output names and descriptions can be obtained via
          `swaymsg -t get_outputs`.
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

      adaptiveSync = mkOption {
        type = types.nullOr types.bool;
        default = null;
        example = true;
        description = ''
          Enables or disables adaptive synchronization
          (aka. Variable Refresh Rate).
        '';
      };
    };
  };

  outputStr =
    { criteria, status, mode, position, scale, transform, adaptiveSync, ... }:
    ''output "${criteria}"'' + optionalString (status != null) " ${status}"
    + optionalString (mode != null) " mode ${mode}"
    + optionalString (position != null) " position ${position}"
    + optionalString (scale != null) " scale ${toString scale}"
    + optionalString (transform != null) " transform ${transform}"
    + optionalString (adaptiveSync != null)
    " adaptive_sync ${if adaptiveSync then "on" else "off"}";

  profileModule = types.submodule {
    options = {
      outputs = mkOption {
        type = types.listOf outputModule;
        default = [ ];
        description = ''
          Outputs configuration.
        '';
      };

      name = mkOption {
        type = types.str;
        default = "";
        description = ''
          Profile name
        '';
      };

      exec = mkOption {
        type = with types; coercedTo str singleton (listOf str);
        default = [ ];
        example =
          "[ \${pkg.sway}/bin/swaymsg workspace 1, move workspace to eDP-1 ]";
        description = ''
          Commands executed after the profile is successfully applied.
          Note that if you provide multiple commands, they will be
          executed asynchronously with no guaranteed ordering.
        '';
      };
    };
  };

  profileStr = { outputs, exec, ... }@args: ''
    profile ${args.name or ""} {
      ${
        concatStringsSep "\n  "
        (map outputStr outputs ++ map (cmd: "exec ${cmd}") exec)
      }
    }
  '';
in {

  meta.maintainers = [ hm.maintainers.nurelin ];

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
        Attribute set of profiles.
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

    settings = mkOption {
      type = types.listOf directivesTag;
      default = [ ];
      description = ''
        Ordered list of directives.
        See kanshi(5) for informations.
      '';
      example = literalExpression ''
        { include = "path/to/included/files"; }
        { output.criteria = "eDP-1";
          output.scale = 2;
        }
        { profile.name = "undocked";
          profile.outputs = [
            {
              criteria = "eDP-1";
            }
          ];
        }
        { profile.name = "docked";
          profile.outputs = [
            {
              criteria = "eDP-1";
            }
            {
              criteria = "Some Company ASDF 4242";
              transform = "90";
            }
          ];
        }
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

  config = mkIf cfg.enable (mkMerge [
    {
      assertions = [
        (lib.hm.assertions.assertPlatform "services.kanshi" pkgs
          lib.platforms.linux)
        {
          assertion = (cfg.profiles == { } && cfg.extraConfig == "")
            || (length cfg.settings) == 0;
          message =
            "Cannot mix kanshi.settings with kanshi.profiles or kanshi.extraConfig";
        }
      ];
    }

    (mkIf (cfg.profiles != { }) {
      warnings = [
        "kanshi.profiles option is deprecated. Use kanshi.settings instead."
      ];
    })

    (mkIf (cfg.extraConfig != "") {
      warnings = [
        "kanshi.extraConfig option is deprecated. Use kanshi.settings instead."
      ];
    })

    {
      xdg.configFile."kanshi/config".text =
        if cfg.profiles == { } && cfg.extraConfig == "" then
          directivesStr
        else
          oldDirectivesStr;

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
    }
  ]);
}
