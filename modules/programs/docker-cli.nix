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
  meta.maintainers = [
    lib.maintainers.friedrichaltheide
    lib.maintainers.will-lol
  ];

  options.programs.docker-cli = {
    enable = mkEnableOption "management of docker client config";

    configDir = mkOption {
      type = lib.types.str;
      default = ".docker";
      description = ''
        Folder relative to the user's home directory where the Docker CLI settings should be stored.
      '';
    };

    contexts = mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          freeformType = jsonFormat.type;
          options.Name = lib.mkOption {
            type = lib.types.str;
            description = "The name of the Docker context";
          };
        }
      );
      default = [ ];
      example = lib.literalExpression ''
        [
          {
            Name = "example";
            Metadata = {
              Description = "example1";

            };
            Endpoints = {
              docker = {
                Host = "unix://example2";
              };
            };
          }
        ];
      '';
      description = ''
        Array of docker context configurations. See:
        <https://docs.docker.com/engine/manage-resources/contexts/
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
      }
      // builtins.listToAttrs (
        map (s: {
          name = "${cfg.configDir}/contexts/meta/${builtins.hashString "sha256" s.Name}/meta.json";
          value = {
            source = jsonFormat.generate "config.json" s;
          };
        }) cfg.contexts
      );
    };
  };
}
