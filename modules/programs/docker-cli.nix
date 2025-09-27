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
    lib.hm.maintainers.will-lol
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
      type = lib.types.attrsOf (
        lib.types.submodule {
          freeformType = jsonFormat.type;
        }
      );
      default = { };
      example = lib.literalExpression ''
        {
          example = {
            Metadata = { Description = "example1"; };
            Endpoints.docker.Host = "unix://example2";
          };
        }
      '';
      description = ''
        Attrset of docker context configurations keyed by context name. See:
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
      // lib.mapAttrs' (
        n: ctx:
        let
          name = if ctx ? Name then ctx.Name else n;
          path = "${cfg.configDir}/contexts/meta/${builtins.hashString "sha256" name}/meta.json";
        in
        {
          name = path;
          value = {
            source = jsonFormat.generate "config.json" (ctx // { Name = name; });
          };
        }
      ) cfg.contexts;
    };
  };
}
