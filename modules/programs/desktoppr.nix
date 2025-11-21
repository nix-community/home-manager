{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.programs.desktoppr;
in

{
  options.programs.desktoppr = {
    enable = lib.mkEnableOption "managing the desktop picture/wallpaper on macOS using desktoppr";
    package = lib.mkPackageOption pkgs "desktoppr" { };

    settings = lib.mkOption {
      type = lib.types.submodule {
        freeformType = with lib.types; attrsOf anything;

        options = {
          picture = lib.mkOption {
            type = with lib.types; nullOr (either path (strMatching "^http(s)?:\/\/.*$"));
            default = null;
            example = "/System/Library/Desktop Pictures/Solid Colors/Stone.png";
            description = ''
              The path to the desktop picture/wallpaper to set. Can also be an HTTP
              or HTTPS URL to retrieve the picture from a remote URL at runtime.
            '';
          };

          sha256 = lib.mkOption {
            type = with lib.types; nullOr (strMatching "^[a-f0-9]{64}$");
            default = null;
            example = "e1e594dec9343b721005a6bf06c48e0aac34ac9a77090e42b543bae9e1e0354a";
            description = ''
              An optional SHA256 checksum of the desktop picture/wallpaper. If the
              specified file does not match the checksum, it will not be set.
            '';
          };

          color = lib.mkOption {
            type = lib.types.strMatching "[0-9a-fA-F]{6}";
            default = "000000";
            example = "2E2E2E";
            description = ''
              The background color that will be used behind the chosen picture when
              it does not fill the screen.
            '';
          };

          scale = lib.mkOption {
            type = lib.types.enum [
              "fill"
              "stretch"
              "center"
              "fit"
            ];
            default = "fill";
            example = "fit";
            description = ''
              The scaling behavior to use when using an image.
            '';
          };

          setOnlyOnce = lib.mkOption {
            type = lib.types.bool;
            default = false;
            example = true;
            description = ''
              If false (the default), the desktop picture/wallpaper will be reset
              to the configured parameters on every system configuration change.

              If true, the desktop picture/wallpaper will only be set when it
              differs from the one previously set. This allows the user to manually
              change the desktop picture/wallpaper after it has been set.
            '';
          };
        };
      };
      default = { };
      example = {
        picture = "/System/Library/Desktop Pictures/Solid Colors/Stone.png";
      };
      description = ''
        The settings to set for desktoppr.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.desktoppr" pkgs lib.platforms.darwin)
    ];

    targets.darwin.defaults.desktoppr = cfg.settings;

    home.activation.desktoppr = lib.hm.dag.entryAfter [ "setDarwinDefaults" ] ''
      verboseEcho "Setting the desktop picture/wallpaper"
      run "${lib.getExe cfg.package}" manage
    '';
  };

  meta.maintainers = with lib.maintainers; [ andre4ik3 ];
}
