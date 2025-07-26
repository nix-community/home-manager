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
    mkOption
    ;

  cfg = config.programs.docker-cli;

  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = [ lib.maintainers.friedrichaltheide ];

  options.programs.docker-cli = {
    enable = mkEnableOption "management of docker client config";

    configDir = mkOption {
      type = lib.types.str;
      default = ".docker";
      description = ''
        Folder relative to the user's home directory where the Docker CLI settings should be stored.
      '';
    };

    settings = mkOption {
      type = jsonFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          "proxies" = {
            "default" = {
              "httpProxy" = "http://proxy.example.org:3128";
              "httpsProxy" = "http://proxy.example.org:3128";
              "noProxy" = "localhost";
            };
          };
      '';
      description = ''
        Available configuration options for the Docker CLI see:
        <https://docs.docker.com/reference/cli/docker/#docker-cli-configuration-file-configjson-properties
      '';
    };
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        DOCKER_CONFIG = "${config.home.homeDirectory}/${cfg.configDir}";
      };

      file = {
        "${cfg.configDir}/config.json" = {
          source = jsonFormat.generate "config.json" cfg.settings;
        };
      };
    };
  };
}
