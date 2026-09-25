{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    ;

  cfg = config.programs.docker-cli;

  jsonFormat = pkgs.formats.json { };

  hasRegistryCredentials = cfg.registryCredentials != { };

  configFile = "${config.home.homeDirectory}/${cfg.configDir}/config.json";

  baseConfigFile = jsonFormat.generate "docker-cli-config.json" cfg.settings;

  registryCredentialsScript = ''
    set -euo pipefail
    PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.jq
      ]
    }''${PATH:+:}$PATH

    configFile=${lib.escapeShellArg configFile}
    mkdir -p "$(dirname "$configFile")"
    install -m 0600 ${baseConfigFile} "$configFile"
  ''
  + lib.concatStringsSep "\n" (
    lib.mapAttrsToList (
      registry: registryCfg:
      let
        passwordFile = lib.escapeShellArg registryCfg.passwordFile;
        username = lib.escapeShellArg registryCfg.username;
        registryArg = lib.escapeShellArg registry;
      in
      ''
        if [ ! -f ${passwordFile} ]; then
          echo "Docker registry password file not found for ${registry}: ${registryCfg.passwordFile}" >&2
          exit 1
        fi

        password=$(cat ${passwordFile})
        auth=$(printf '%s:%s' ${username} "$password" | base64 --wrap=0)
        tmpFile=$(mktemp)
        jq \
          --arg registry ${registryArg} \
          --arg auth "$auth" \
          '.auths[$registry] = { auth: $auth }' \
          "$configFile" > "$tmpFile"
        install -m 0600 "$tmpFile" "$configFile"
        rm -f "$tmpFile"
      ''
    ) cfg.registryCredentials
  );
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
      apply = p: lib.removePrefix "${config.home.homeDirectory}/" p;
      default =
        if config.xdg.enable && lib.versionAtLeast config.home.stateVersion "26.05" then
          "${config.xdg.configHome}/docker"
        else
          ".docker";
      defaultText = lib.literalExpression ''
        if config.xdg.enable && lib.versionAtLeast config.home.stateVersion "26.05" then
          "$XDG_CONFIG_HOME/docker"
        else
          ".docker"
      '';
      example = lib.literalExpression "\${config.xdg.configHome}/docker";
      description = "Directory to store configuration and state. This also sets $DOCKER_CONFIG.";
    };

    contexts = mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
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
      inherit (jsonFormat) type;
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

    registryCredentials = mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            username = mkOption {
              type = lib.types.str;
              description = "Username for the registry.";
            };

            passwordFile = mkOption {
              type = lib.types.str;
              description = ''
                Path to a file containing the registry password or token.

                The file is read during activation and its contents are written
                to the Docker CLI configuration as a base64-encoded auth entry.
              '';
            };
          };
        }
      );
      default = { };
      example = lib.literalExpression ''
        {
          "https://index.docker.io/v1/" = {
            username = "my-user";
            passwordFile = config.age.secrets.docker-hub-token.path;
          };
        }
      '';
      description = ''
        Registry credentials to write to the Docker CLI configuration.

        Attribute names are registry URLs, for example
        `https://index.docker.io/v1/` for Docker Hub. This option writes
        file-backed credentials directly to `config.json` and does not use a
        credential helper or credential store.
      '';
    };
  };

  config = mkIf cfg.enable {
    home = {
      sessionVariables = {
        DOCKER_CONFIG = "${config.home.homeDirectory}/${cfg.configDir}";
      };

      file =
        lib.optionalAttrs (!hasRegistryCredentials) {
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
              source = jsonFormat.generate "config.json" ctx;
            };
          }
        ) cfg.contexts;
    };

    home.activation.dockerCliRegistryCredentials = mkIf hasRegistryCredentials (
      lib.hm.dag.entryAfter [ "writeBoundary" ] registryCredentialsScript
    );
  };
}
