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

  configTarget = "${cfg.configDir}/config.json";
  configFile = "${config.home.homeDirectory}/${configTarget}";

  baseConfigFile = jsonFormat.generate "docker-cli-config.json" cfg.settings;

  registryCredentialsConfig = ''
    set -euo pipefail
    PATH=${
      lib.makeBinPath [
        pkgs.coreutils
        pkgs.jq
      ]
    }''${PATH:+:}$PATH

    candidateConfig=$(cat ${baseConfigFile}) || exit 1
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
          printf 'Docker registry password file not found for %s: %s\n' ${registryArg} ${passwordFile} >&2
          exit 1
        fi

        password=$(cat ${passwordFile}) || exit 1
        auth=$(printf '%s:%s' ${username} "$password" | base64 --wrap=0) || exit 1
        candidateConfig=$(printf '%s' "$candidateConfig" | jq \
          --arg registry ${registryArg} \
          --rawfile auth <(printf '%s' "$auth") \
          '.auths[$registry] = { auth: $auth }' \
        ) || exit 1
      ''
    ) cfg.registryCredentials
  )
  + ''
    printf '%s' "$candidateConfig"
  '';
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
        <https://docs.docker.com/reference/cli/docker/#docker-cli-configuration-file-configjson-properties>

        These settings are written to the world-readable Nix store, so avoid
        putting registry credentials or proxy passwords here. For registry
        credentials, Docker's `credsStore` or `credHelpers` settings can keep
        them in a credential helper instead; see
        [Docker credential stores](https://docs.docker.com/reference/cli/docker/login/#credential-stores).
        Because Home Manager links {file}`config.json` read-only,
        `docker login` still reports an error when it adds a registry to
        that file, even after the credential helper has stored the
        credential. You can store the credential with the helper's own
        `store` command instead.
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

        Credential files are validated before activation changes the home
        directory. The configuration is a generation-owned mutable file:
        activation replaces application edits, removing all credentials returns
        to the ordinary settings symlink, and disabling the module removes the
        managed file. Existing unmanaged files require a backup or explicit force.
        Stop Docker clients before activation. This requires the legacy file
        activator. If activation fails before credentials are published, the
        previous generation's owned configuration is restored.
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
          source = baseConfigFile;
          mutable = hasRegistryCredentials;
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

    home.activation = mkIf hasRegistryCredentials {
      checkDockerCliRegistryCredentials = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        if [[ ! -v DRY_RUN ]]; then
          dockerCliRegistryConfig="$(
            ${registryCredentialsConfig}
          )" || exit 1
        fi
      '';
      prepareDockerCliRegistryCredentials =
        lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
          ''
            if [[ ! -v DRY_RUN ]]; then
              dockerCliRegistryFile=${lib.escapeShellArg configFile}
              dockerCliRegistryTarget=${lib.escapeShellArg configTarget}
              dockerCliRegistryBackup=""
              dockerCliRegistryRestore=false
              dockerCliRegistryPreviousExitTrap="$(trap -p EXIT)"
              function dockerCliRegistryCleanup() {
                local status="$1"
                trap - EXIT
                if [[ "$dockerCliRegistryRestore" == true && $status -ne 0 ]]; then
                  if checkMutableParents "$dockerCliRegistryTarget" &&
                      mv -T -- "$dockerCliRegistryBackup/config" "$dockerCliRegistryFile"; then
                    dockerCliRegistryRestore=false
                  else
                    errorEcho "Could not restore Docker configuration; recovery copy retained at '$dockerCliRegistryBackup/config'."
                    status=1
                  fi
                fi
                if [[ "$dockerCliRegistryRestore" == false && -n "$dockerCliRegistryBackup" ]]; then
                  rm -f -- "$dockerCliRegistryBackup/config"
                  rmdir -- "$dockerCliRegistryBackup"
                fi
                # Run the pre-existing EXIT handler in a subshell, including HM's
                # GC-root cleanup, without recursively invoking this handler.
                if [[ -n "$dockerCliRegistryPreviousExitTrap" ]]; then
                  (eval "$dockerCliRegistryPreviousExitTrap"; exit "$status") || status=$?
                fi
                exit "$status"
              }
              trap 'dockerCliRegistryCleanup "$?"' EXIT
              if [[ -v oldGenPath ]] &&
                  [[ ( -L "$oldGenPath/home-mutable-files/$dockerCliRegistryTarget" &&
                       -f "$dockerCliRegistryFile" && ! -L "$dockerCliRegistryFile" ) ||
                     ( -L "$dockerCliRegistryFile" &&
                       "$(readlink "$dockerCliRegistryFile")" == "$(readlink -e "$oldGenPath/home-files")/$dockerCliRegistryTarget" ) ]]; then
                dockerCliRegistryBackup=$(mktemp -d "$dockerCliRegistryFile.rollback.XXXXXX") || exit 1
                cp -pP -- "$dockerCliRegistryFile" "$dockerCliRegistryBackup/config" || exit 1
                dockerCliRegistryRestore=true
              fi
            fi
          '';
      dockerCliRegistryCredentials = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        (
          set -euo pipefail
          PATH=${lib.makeBinPath [ pkgs.coreutils ]}''${PATH:+:}$PATH
          configFile=${lib.escapeShellArg configFile}
          if [[ -v DRY_RUN ]]; then
            echo "Would update Docker registry credentials in '$configFile'."
            exit 0
          fi
          umask 077
          tmpFile=$(mktemp "$configFile.XXXXXX") || exit 1
          trap 'rm -f -- "$tmpFile"' EXIT
          printf '%s\n' "$dockerCliRegistryConfig" > "$tmpFile" || exit 1
          mv -T -- "$tmpFile" "$configFile" || exit 1
        ) || exit 1
        if [[ ! -v DRY_RUN ]]; then
          dockerCliRegistryRestore=false
          if [[ -n "$dockerCliRegistryBackup" ]]; then
            rm -f -- "$dockerCliRegistryBackup/config"
            rmdir -- "$dockerCliRegistryBackup"
          fi
          trap - EXIT
          eval "$dockerCliRegistryPreviousExitTrap"
          unset dockerCliRegistryFile dockerCliRegistryTarget dockerCliRegistryBackup \
            dockerCliRegistryRestore dockerCliRegistryPreviousExitTrap
          unset -f dockerCliRegistryCleanup
        fi
        unset dockerCliRegistryConfig
      '';
    };
  };
}
