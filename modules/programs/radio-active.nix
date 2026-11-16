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

      wrapPlayer =
        package: playerName: playerPackage:
        pkgs.symlinkJoin {
          name = "${lib.getName package}-${playerName}";
          paths = [ package ];
          meta = package.meta or { };
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            for executable in "$out"/bin/*; do
              if [ -f "$executable" ] && [ -x "$executable" ]; then
                wrapProgram "$executable" \
                  --prefix PATH : ${lib.makeBinPath [ playerPackage ]}
              fi
            done
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
          wrapPlayer cfg.package player pkgs.${player}
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
