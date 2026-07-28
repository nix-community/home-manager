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
      type = attrsOf (
        attrsOf (oneOf [
          nonEmptyStr
          nonnegative
        ])
      );
      default = { };
      example.AppConfig = {
        filepath = "/home/{user}/recordings/radioactive/";
        filetype = "mp3";
        filter = "none";
        limit = 41;
        loglevel = "debug";
        player = "ffplay";
        sort = "votes";
        volume = 68;
      };
      description = ''
        Declare-able configurations for radio-active written to
        {file}`$XDG_CONFIG_HOME/radio-active/configs.ini`.
      '';
    };

    aliases = mkOption {
      type = attrsOf nonEmptyStr;
      default = { };
      example = {
        "Deep House Lounge" = "http://198.15.94.34:8006/stream";
      };
      description = ''
        Key/value pairs where the key is name of radio station and value is URL.
      '';
    };
  };

  config =
    let
      player = attrByPath [ "settings" "AppConfig" "player" ] "ffplay" cfg;

      patchPlayer =
        package: playerName: playerPackage:
        if package ? overrideAttrs then
          package.overrideAttrs (
            _finalAttrs: previousAttrs:
            let
              previousPostPatch = previousAttrs.postPatch or null;
            in
            {
              postPatch = lib.optionalString (previousPostPatch != null) "${previousPostPatch}\n" + ''
                substituteInPlace radioactive/${playerName}.py \
                  --replace-fail 'self.exe_path = which(self.program_name)' \
                  'self.exe_path = "${lib.getExe playerPackage}"'
              '';
            }
          )
        else
          pkgs.symlinkJoin {
            name = "${lib.getName package}-${playerName}";
            paths = [ package ];
            nativeBuildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram "$out/bin/${baseNameOf (lib.getExe package)}" \
                --prefix PATH : ${lib.makeBinPath [ playerPackage ]}
            '';
          };

      knownPlayers = [
        "ffplay"
        "mpv"
        "vlc"
      ];
    in
    mkIf cfg.enable {
      warnings = lib.optional (builtins.elem player knownPlayers == false) ''
        Unknown player defined in `programs.radio-active.settings.AppConfig.player`
      '';

      home.packages = lib.optional (cfg.package != null) (
        if
          builtins.elem player [
            "mpv"
            "vlc"
          ]
        then
          patchPlayer cfg.package player pkgs.${player}
        else
          cfg.package
      );

      xdg.configFile."radio-active/configs.ini" = lib.mkIf (cfg.settings != { }) {
        source = iniFormat.generate "radio-active-config" cfg.settings;
      };

      home.file.".radio-active-alias" = mkIf (cfg.aliases != { }) {
        text = ''
          ${builtins.concatStringsSep "\n" (mapAttrsToList (name: value: "${name}==${value}") cfg.aliases)}
        '';
      };
    };
}
