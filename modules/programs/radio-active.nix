{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    mkPackageOption
    ;

  inherit (lib.attrsets)
    attrByPath
    ;

  inherit (lib.types)
    nonEmptyStr
    submodule
    attrsOf
    oneOf
    ;

  inherit (lib.types.numbers)
    nonnegative
    ;

  inherit (pkgs.formats)
    ini
    ;

  iniFormat = ini { };

  cfg = config.programs.radio-active;
in
{
  meta.maintainers = [
    lib.maintainers.S0AndS0
  ];

  options.programs.radio-active = {
    enable = mkEnableOption "Enable installing radio-active and writing configuration file";

    package = mkPackageOption pkgs "radio-active" {
      nullable = true;
    };

    settings = mkOption {
      default = { };

      type = submodule {
        options = {
          AppConfig = mkOption {
            default = { };

            description = ''
              Declare-able configurations for radio-active
            '';

            example = ''
              ## Input

              ```nix
              programs.radio-active.settings.AppConfig = {
                loglevel = "debug";
                limit = 41;
                sort = "votes";
                filter = "none";
                volume = 68;
                filepath = "/home/{user}/recordings/radioactive/";
                filetype = "mp3";
                player = "ffplay";
              };
              ```

              ## Output

              ```
              [AppConfig]
              loglevel = debug
              limit = 41
              sort = votes
              filter = none
              volume = 68
              filepath = /home/{user}/recordings/radioactive/
              filetype = mp3
              player = ffplay
              ```
            '';

            type = attrsOf (oneOf [
              nonEmptyStr
              nonnegative
            ]);
          };

          aliases = mkOption {
            description = ''
              Key/value pairs where the key is name of radio station and value is URL
            '';

            example = ''
              ## Input

              ```nix
              programs.radio-active.aliases = {
                "Deep House Lounge" = "http://198.15.94.34:8006/stream";
              };
              ```

              ## Output

              ```
              Deep House Lounge==http://198.15.94.34:8006/stream
              ```
            '';

            default = { };
            type = attrsOf nonEmptyStr;
          };
        };
      };
    };
  };

  config = mkIf cfg.enable {
    ## TODO: test that dependency `postPatch` modifications works at runtime
    home.packages =
      let
        player = attrByPath [ "settings" "AppConfig" "player" ] "ffplay" cfg;

        radio-active =
          if player == "ffplay" then
            pkgs.radio-active
          else if player == "mpv" then
            pkgs.radio-active.overrideAttrs (
              finalAttrs: previousAttrs: {
                postPatch = ''
                  ${previousAttrs.postPatch}

                  substituteInPlace radioactive/mpv.py \
                    --replace-fail 'self.exe_path = which(self.program_name)' \
                    'self.exe_path = "${lib.getExe pkgs.mpv}"'
                '';
              }
            )
          else if player == "vlc" then
            pkgs.radio-active.overrideAttrs (
              finalAttrs: previousAttrs: {
                postPatch = ''
                  ${previousAttrs.postPatch}

                  substituteInPlace radioactive/vlc.py \
                    --replace-fail 'self.exe_path = which(self.program_name)' \
                    'self.exe_path = "${lib.getExe pkgs.vlc}"'
                '';
              }
            )
          else
            lib.warn ''
              Unknown player defined in `config.programs.radio-active.AppConfig.player`
            '' pkgs.radio-active;
      in
      mkIf (cfg.package != null) [
        radio-active
      ];

    xdg.configFile."radio-active/configs.ini" =
      lib.mkIf (cfg.settings != { } && cfg.settings.AppConfig != { })
        {
          source = iniFormat.generate "radio-active-config" {
            inherit (cfg.settings) AppConfig;
          };
        };

    home.file."radio-active-alias" = mkIf (cfg.settings != { } && cfg.settings.aliases != { }) {
      text = ''
        ${builtins.concatStringsSep "\n" (
          mapAttrsToList (name: value: "${name}==${value}") cfg.settings.aliases
        )}
      '';
      target = "${config.home.homeDirectory}/.radio-active-alias";
    };
  };
}
