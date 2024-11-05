{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.autorandr;

  matrixOf = n: m: elemType:
    mkOptionType rec {
      name = "matrixOf";
      description =
        "${toString n}×${toString m} matrix of ${elemType.description}s";
      check = xss:
        let listOfSize = l: xs: isList xs && length xs == l;
        in listOfSize n xss
        && all (xs: listOfSize m xs && all elemType.check xs) xss;
      merge = mergeOneOption;
      getSubOptions = prefix: elemType.getSubOptions (prefix ++ [ "*" "*" ]);
      getSubModules = elemType.getSubModules;
      substSubModules = mod: matrixOf n m (elemType.substSubModules mod);
      functor = (defaultFunctor name) // { wrapped = elemType; };
    };

  profileModule = types.submodule {
    options = {
      fingerprint = mkOption {
        type = types.attrsOf types.str;
        description = ''
          Output name to EDID mapping.
          Use `autorandr --fingerprint` to get current setup values.
        '';
        default = { };
      };

      config = mkOption {
        type = types.attrsOf configModule;
        description = "Per output profile configuration.";
        default = { };
      };

      hooks = mkOption {
        type = profileHooksModule;
        description = "Profile hook scripts.";
        default = { };
      };
    };
  };

  configModule = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        description = "Whether to enable the output.";
        default = true;
      };

      crtc = mkOption {
        type = types.nullOr types.ints.unsigned;
        description = "Output video display controller.";
        default = null;
        example = 0;
      };

      primary = mkOption {
        type = types.bool;
        description = "Whether output should be marked as primary";
        default = false;
      };

      position = mkOption {
        type = types.str;
        description = "Output position";
        default = "";
        example = "5760x0";
      };

      mode = mkOption {
        type = types.str;
        description = "Output resolution.";
        default = "";
        example = "3840x2160";
      };

      rate = mkOption {
        type = types.str;
        description = "Output framerate.";
        default = "";
        example = "60.00";
      };

      gamma = mkOption {
        type = types.str;
        description = "Output gamma configuration.";
        default = "";
        example = "1.0:0.909:0.833";
      };

      rotate = mkOption {
        type = types.nullOr (types.enum [ "normal" "left" "right" "inverted" ]);
        description = "Output rotate configuration.";
        default = null;
        example = "left";
      };

      transform = mkOption {
        type = types.nullOr (matrixOf 3 3 types.float);
        default = null;
        example = literalExpression ''
          [
            [ 0.6 0.0 0.0 ]
            [ 0.0 0.6 0.0 ]
            [ 0.0 0.0 1.0 ]
          ]
        '';
        description = ''
          Refer to
          {manpage}`xrandr(1)`
          for the documentation of the transform matrix.
        '';
      };

      dpi = mkOption {
        type = types.nullOr types.ints.positive;
        description = "Output DPI configuration.";
        default = null;
        example = 96;
      };

      scale = mkOption {
        type = types.nullOr (types.submodule {
          options = {
            method = mkOption {
              type = types.enum [ "factor" "pixel" ];
              description = "Output scaling method.";
              default = "factor";
              example = "pixel";
            };

            x = mkOption {
              type = types.either types.float types.ints.positive;
              description = "Horizontal scaling factor/pixels.";
            };

            y = mkOption {
              type = types.either types.float types.ints.positive;
              description = "Vertical scaling factor/pixels.";
            };
          };
        });
        description = ''
          Output scale configuration.

          Either configure by pixels or a scaling factor. When using pixel method the
          {manpage}`xrandr(1)`
          option
          `--scale-from`
          will be used; when using factor method the option
          `--scale`
          will be used.

          This option is a shortcut version of the transform option and they are mutually
          exclusive.
        '';
        default = null;
        example = literalExpression ''
          {
            x = 1.25;
            y = 1.25;
          }
        '';
      };

      filter = mkOption {
        type = types.nullOr (types.enum [ "bilinear" "nearest" ]);
        description = "Interpolation method to be used for scaling the output.";
        default = null;
        example = "nearest";
      };

      extraConfig = mkOption {
        type = types.lines;
        description = "Extra lines to append to this profile's config.";
        default = "";
        example = literalExpression ''
          '''
            x-prop-non_desktop 0
            some-key some-value
          '''
        '';
      };
    };
  };

  hookType = types.lines;

  globalHooksModule = types.submodule {
    options = {
      postswitch = mkOption {
        type = types.attrsOf hookType;
        description = "Postswitch hook executed after mode switch.";
        default = { };
      };

      preswitch = mkOption {
        type = types.attrsOf hookType;
        description = "Preswitch hook executed before mode switch.";
        default = { };
      };

      predetect = mkOption {
        type = types.attrsOf hookType;
        description = ''
          Predetect hook executed before autorandr attempts to run xrandr.
        '';
        default = { };
      };
    };
  };

  profileHooksModule = types.submodule {
    options = {
      postswitch = mkOption {
        type = hookType;
        description = "Postswitch hook executed after mode switch.";
        default = "";
      };

      preswitch = mkOption {
        type = hookType;
        description = "Preswitch hook executed before mode switch.";
        default = "";
      };

      predetect = mkOption {
        type = hookType;
        description = ''
          Predetect hook executed before autorandr attempts to run xrandr.
        '';
        default = "";
      };
    };
  };

  hookToFile = folder: name: hook:
    nameValuePair "autorandr/${folder}/${name}" {
      source = "${pkgs.writeShellScriptBin "hook" hook}/bin/hook";
    };
  profileToFiles = name: profile:
    with profile;
    mkMerge ([
      {
        "autorandr/${name}/setup".text = concatStringsSep "\n"
          (mapAttrsToList fingerprintToString fingerprint);
        "autorandr/${name}/config".text =
          concatStringsSep "\n" (mapAttrsToList configToString profile.config);
      }
      (mkIf (hooks.postswitch != "")
        (listToAttrs [ (hookToFile name "postswitch" hooks.postswitch) ]))
      (mkIf (hooks.preswitch != "")
        (listToAttrs [ (hookToFile name "preswitch" hooks.preswitch) ]))
      (mkIf (hooks.predetect != "")
        (listToAttrs [ (hookToFile name "predetect" hooks.predetect) ]))
    ]);
  fingerprintToString = name: edid: "${name} ${edid}";
  configToString = name: config:
    if config.enable then
      concatStringsSep "\n" ([ "output ${name}" ]
        ++ optional (config.position != "") "pos ${config.position}"
        ++ optional (config.crtc != null) "crtc ${toString config.crtc}"
        ++ optional config.primary "primary"
        ++ optional (config.dpi != null) "dpi ${toString config.dpi}"
        ++ optional (config.gamma != "") "gamma ${config.gamma}"
        ++ optional (config.mode != "") "mode ${config.mode}"
        ++ optional (config.rate != "") "rate ${config.rate}"
        ++ optional (config.rotate != null) "rotate ${config.rotate}"
        ++ optional (config.filter != null) "filter ${config.filter}"
        ++ optional (config.transform != null) ("transform "
          + concatMapStringsSep "," toString (flatten config.transform))
        ++ optional (config.scale != null)
        ((if config.scale.method == "factor" then "scale" else "scale-from")
          + " ${toString config.scale.x}x${toString config.scale.y}")
        ++ optional (config.extraConfig != "") config.extraConfig)
    else ''
      output ${name}
      off
    '';

in {
  options = {
    programs.autorandr = {
      enable = mkEnableOption "Autorandr";

      hooks = mkOption {
        type = globalHooksModule;
        description = "Global hook scripts";
        default = { };
        example = literalExpression ''
          {
            postswitch = {
              "notify-i3" = "''${pkgs.i3}/bin/i3-msg restart";
              "change-background" = readFile ./change-background.sh;
              "change-dpi" = '''
                case "$AUTORANDR_CURRENT_PROFILE" in
                  default)
                    DPI=120
                    ;;
                  home)
                    DPI=192
                    ;;
                  work)
                    DPI=144
                    ;;
                  *)
                    echo "Unknown profile: $AUTORANDR_CURRENT_PROFILE"
                    exit 1
                esac

                echo "Xft.dpi: $DPI" | ''${pkgs.xorg.xrdb}/bin/xrdb -merge
              '''
            };
          }
        '';
      };

      profiles = mkOption {
        type = types.attrsOf profileModule;
        description = "Autorandr profiles specification.";
        default = { };
        example = literalExpression ''
          {
            "work" = {
              fingerprint = {
                eDP1 = "<EDID>";
                DP1 = "<EDID>";
              };
              config = {
                eDP1.enable = false;
                DP1 = {
                  enable = true;
                  crtc = 0;
                  primary = true;
                  position = "0x0";
                  mode = "3840x2160";
                  gamma = "1.0:0.909:0.833";
                  rate = "60.00";
                  rotate = "left";
                };
              };
              hooks.postswitch = readFile ./work-postswitch.sh;
            };
          }
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = flatten (mapAttrsToList (profile:
      { config, ... }:
      mapAttrsToList (output: opts: {
        assertion = opts.scale == null || opts.transform == null;
        message = ''
          Cannot use the profile output options 'scale' and 'transform' simultaneously.
          Check configuration for: programs.autorandr.profiles.${profile}.config.${output}
        '';
      }) config) cfg.profiles);

    home.packages = [ pkgs.autorandr ];
    xdg.configFile = mkMerge ([
      (mapAttrs' (hookToFile "postswitch.d") cfg.hooks.postswitch)
      (mapAttrs' (hookToFile "preswitch.d") cfg.hooks.preswitch)
      (mapAttrs' (hookToFile "predetect.d") cfg.hooks.predetect)
      (mkMerge (mapAttrsToList profileToFiles cfg.profiles))
    ]);
  };

  meta.maintainers = [ maintainers.uvnikita ];
}
