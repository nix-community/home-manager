{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.autorandr;

  matrixOf = n: m: elemType: mkOptionType rec {
    name = "matrixOf";
    description = "${toString n}×${toString m} matrix of ${elemType.description}s";
    check = xss:
      let
        listOfSize = l: xs: isList xs && length xs == l;
      in
        listOfSize n xss && all (xs: listOfSize m xs && all elemType.check xs) xss;
    merge = mergeOneOption;
    getSubOptions = prefix: elemType.getSubOptions (prefix ++ ["*" "*"]);
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
          Use <code>autorandr --fingerprint</code> to get current setup values.
        '';
        default = {};
      };

      config = mkOption {
        type = types.attrsOf configModule;
        description = "Per output profile configuration.";
        default = {};
      };

      hooks = mkOption {
        type = profileHooksModule;
        description = "Profile hook scripts.";
        default = {};
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
        type = types.nullOr (types.enum ["normal" "left" "right" "inverted"]);
        description = "Output rotate configuration.";
        default = null;
        example = "left";
      };

      transform = mkOption {
        type = types.nullOr (matrixOf 3 3 types.float);
        default = null;
        example = literalExample ''
          [
            [ 0.6 0.0 0.0 ]
            [ 0.0 0.6 0.0 ]
            [ 0.0 0.0 1.0 ]
          ]
        '';
        description = ''
          Refer to
          <citerefentry>
            <refentrytitle>xrandr</refentrytitle>
            <manvolnum>1</manvolnum>
          </citerefentry>
          for the documentation of the transform matrix.
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
        default = {};
      };

      preswitch = mkOption {
        type = types.attrsOf hookType;
        description = "Preswitch hook executed before mode switch.";
        default = {};
      };

      predetect = mkOption {
        type = types.attrsOf hookType;
        description = "Predetect hook executed before autorandr attempts to run xrandr.";
        default = {};
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
        description = "Predetect hook executed before autorandr attempts to run xrandr.";
        default = "";
      };
    };
  };

  hookToFile = folder: name: hook:
    nameValuePair
      "autorandr/${folder}/${name}"
      { source = "${pkgs.writeShellScriptBin "hook" hook}/bin/hook"; };
  profileToFiles = name: profile: with profile; mkMerge ([
    {
      "autorandr/${name}/setup".text = concatStringsSep "\n" (mapAttrsToList fingerprintToString fingerprint);
      "autorandr/${name}/config".text = concatStringsSep "\n" (mapAttrsToList configToString profile.config);
    }
    (mkIf (hooks.postswitch != "") (listToAttrs [ (hookToFile name "postswitch" hooks.postswitch) ]))
    (mkIf (hooks.preswitch != "") (listToAttrs [ (hookToFile name "preswitch" hooks.preswitch) ]))
    (mkIf (hooks.predetect != "") (listToAttrs [ (hookToFile name "predetect" hooks.predetect) ]))
  ]);
  fingerprintToString = name: edid: "${name} ${edid}";
  configToString = name: config: if config.enable then ''
    output ${name}
    ${optionalString (config.position != "") "pos ${config.position}"}
    ${optionalString config.primary "primary"}
    ${optionalString (config.gamma != "") "gamma ${config.gamma}"}
    ${optionalString (config.mode != "") "mode ${config.mode}"}
    ${optionalString (config.rate != "") "rate ${config.rate}"}
    ${optionalString (config.rotate != null) "rotate ${config.rotate}"}
    ${optionalString (config.transform != null) (
      "transform " + concatMapStringsSep "," toString (flatten config.transform)
    )}
  '' else ''
    output ${name}
    off
  '';

in

{
  options = {
    programs.autorandr = {
      enable = mkEnableOption "Autorandr";

      hooks = mkOption {
        type = globalHooksModule;
        description = "Global hook scripts";
        default = {};
        example = literalExample ''
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
                  echo "Unknown profle: $AUTORANDR_CURRENT_PROFILE"
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
        default = {};
        example = literalExample ''
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
    home.packages = [ pkgs.autorandr ];
    xdg.configFile = mkMerge ([
      (mapAttrs' (hookToFile "postswitch.d") cfg.hooks.postswitch)
      (mapAttrs' (hookToFile "preswitch.d")  cfg.hooks.preswitch)
      (mapAttrs' (hookToFile "predetect.d")  cfg.hooks.predetect)
      (mkMerge (mapAttrsToList profileToFiles cfg.profiles))
    ]);
  };

  meta.maintainers = [ maintainers.uvnikita ];
}
