{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    literalExpression
    mkOption
    optionalAttrs
    types
    ;

  cfg = config.programs.sm64ex;

  # This is required for tests, we cannot overwrite the dummy package.
  package =
    if cfg.region == null && cfg.baserom == null && cfg.extraCompileFlags == null then
      cfg.package
    else
      cfg.package.override (
        attrs:
        { }
        // optionalAttrs (cfg.region != null) { region = cfg.region; }
        // optionalAttrs (cfg.baserom != null) { baseRom = cfg.baserom; }
        // optionalAttrs (cfg.extraCompileFlags != null) {
          compileFlags = cfg.extraCompileFlags;
        }
      );

  mkConfig =
    key: value:
    let
      generatedValue =
        if lib.isBool value then
          (if value then "true" else "false")
        else if lib.isList value then
          lib.concatStringsSep " " value
        else
          toString value;
    in
    "${key} ${generatedValue}";

in
{
  meta.maintainers = [ ];

  options.programs.sm64ex = {
    enable = lib.mkEnableOption "sm64ex";

    package = lib.mkPackageOption pkgs "sm64ex" { nullable = true; };

    region = mkOption {
      type = types.nullOr (
        types.enum [
          "us"
          "eu"
          "jp"
        ]
      );
      default = null;
      defaultText = literalExpression "us"; # This is set both in nixpkgs and upstream
      description = ''
        Your baserom's region. Note that only "us", "eu", and "jp" are supported.
      '';
      example = literalExpression "jp";
    };

    baserom = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "The path to the Super Mario 64 baserom to extract assets from.";
      example = literalExpression "/home/foo/baserom.us.z64";
    };

    extraCompileFlags = mkOption {
      type = with types; nullOr (listOf str);
      default = null;
      description = ''
        Extra flags to pass to the compiler. See
        <https://github.com/sm64pc/sm64ex/wiki/Build-options>
        for more information.
      '';
      example = literalExpression ''
        [
          "BETTERCAMERA=1"
          "NODRAWINGDISTANCE=1"
        ];
      '';
    };

    settings = mkOption {
      type = with types; nullOr (attrsOf (either str (either int (either bool (listOf str)))));
      default = null;
      description = "Settings for sm64ex's {file}`$XDG_DATA_HOME/sm64pc/sm64config.txt` file.";
      example = literalExpression ''
        {
          fullscreen = false;
          window_x = 0;
          window_y = 0;
          window_w = 1920;
          window_h = 1080;
          vsync = 1;
          texture_filtering = 1;
          master_volume = 127;
          music_volume = 127;
          sfx_volume = 127;
          env_volume = 127;
          key_a = [ "0026" "1000" "1103" ];
          key_b = [ "0033" "1002" "1101" ];
          key_start = [ "0039" "1006" "ffff" ];
          key_l = [ "0034" "1007" "1104" ];
          key_r = [ "0036" "100a" "1105" ];
          key_z = [ "0025" "1009" "1102" ];
          key_cup = [ "100b" "ffff" "ffff" ];
          key_cdown = [ "100c" "ffff" "ffff" ];
          key_cleft = [ "100d" "ffff" "ffff" ];
          key_cright = [ "100e" "ffff" "ffff" ];
          key_stickup = [ "0011" "ffff" "ffff" ];
          key_stickdown = [ "001f" "ffff" "ffff" ];
          key_stickleft = [ "001e" "ffff" "ffff" ];
          key_stickright = [ "0020" "ffff" "ffff" ];
          stick_deadzone = 16;
          rumble_strength = 10;
          skip_intro = 1;
        };
      '';
    };
  };

  config =
    let
      configFile = lib.optionals (cfg.settings != null) (
        lib.concatStringsSep "\n" (lib.mapAttrsToList mkConfig cfg.settings)
      );
    in
    lib.mkIf cfg.enable {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

      xdg.dataFile."sm64pc/sm64config.txt" = lib.mkIf (cfg.settings != null) { text = configFile; };
    };
}
