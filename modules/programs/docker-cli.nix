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
        lib.types.submodule (
          { name, config, ... }:
          {
            freeformType = jsonFormat.type;
            options = {
              Name = mkOption {
                type = lib.types.str;
                readOnly = true;
                description = "Name of the Docker context. Defaults to the attribute name (the <name> in programs.docker-cli.contexts.<name>). Overriding requires lib.mkForce.";
              };
            };
            config.Name = name;
          }
        )
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
        Attribute set of Docker context configurations. Each attribute name becomes the context Name; overriding requires lib.mkForce. See:
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
        _n: ctx:
        let
          path = "${cfg.configDir}/contexts/meta/${builtins.hashString "sha256" ctx.Name}/meta.json";
        in
        {
          name = path;
          value = {
            source = jsonFormat.generate "config.json" (ctx);
          };
        }
      ) cfg.contexts;
    };
  };
}
