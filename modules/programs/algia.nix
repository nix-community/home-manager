{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.algia;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.algia = {
    enable = mkEnableOption "algia";
    package = mkPackageOption pkgs "algia" { nullable = true; };
    settings = mkOption {
      inherit (jsonFormat) type;
      default = { };
      example = {
        relays = {
          "wss =//relay-jp.nostr.wirednet.jp" = {
            read = true;
            write = true;
            search = false;
          };
        };
        privatekey = "nsecXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX";
      };
      description = ''
        Configuration settings for algia. All the available options can be found here:
        <https://github.com/mattn/algia?tab=readme-ov-file#configuration>
      '';
    };
  };

  config =
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then
          ".config/algia"
        else
          "${lib.removePrefix config.home.homeDirectory config.xdg.configHome}/algia";
    in
    mkIf cfg.enable {
      home.packages = mkIf (cfg.package != null) [ cfg.package ];
      home.file."${configDir}/config.json" = mkIf (cfg.settings != { }) {
        source = jsonFormat.generate "algia-config.json" cfg.settings;
      };
    };
}
