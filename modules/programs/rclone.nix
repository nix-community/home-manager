{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rclone;
  iniFormat = pkgs.formats.ini { };
  replaceIllegalChars = builtins.replaceStrings [ "/" " " "$" ] [ "." "_" "" ];
  isUsingSecretProvisioner = name: config ? "${name}" && config."${name}".secrets != { };

  # serve protocols that can use `Type=notify` services, this is determined from rclone source code
  serveProtocolNotifies = [
    "dlna"
    "http"
    "restic"
    "webdav"
  ];

  # options shared between mounts/serve
  mountServeOptions = {
    logLevel = lib.mkOption {
      type = lib.types.enum [
        null
        "ERROR"
        "NOTICE"
        "INFO"
        "DEBUG"
      ];
      default = null;
      example = "INFO";
      description = ''
        Set the log level. See <https://rclone.org/docs/#logging> for more.
      '';
    };
    options = lib.mkOption {
      type =
        with lib.types;
        attrsOf (
          nullOr (oneOf [
            bool
            int
            float
            str
          ])
        );
      default = { };
      apply = lib.mergeAttrs {
        vfs-cache-mode = "full";
        # On Linux the unit runs under systemd, so keep the %C specifier:
        # it is expanded at unit-start time to the live $XDG_CACHE_HOME
        # (falling back to ~/.cache), preserving the pre-Darwin behavior
        # even for users who set XDG_CACHE_HOME outside Home Manager.
        # launchd has no equivalent specifier, so Darwin must use the
        # Home Manager-evaluated path.
        cache-dir =
          if pkgs.stdenv.hostPlatform.isLinux then "%C/rclone" else "${config.xdg.cacheHome}/rclone";
      };
      description = ''
        An attribute set of option values passed to the command.
        To set a boolean option, assign it `true` or `false`. See
        <https://nixos.org/manual/nixpkgs/stable/#function-library-lib.cli.toCommandLineShellGNU>
        for more details on the format.

        Some caching options are set by default, namely `vfs-cache-mode = "full"`
        and `cache-dir`. These can be overridden if desired.
      '';
    };
  };

  # Builder for a per-sidecar systemd user unit. Returns the value half
  # of a `nameValuePair` (the unit attrs).
  mkSystemdSidecar =
    {
      sidecarType,
      remoteName,
      sidecar,
      sidecarPath,
      isMount,
      cmdName,
    }:
    {
      Unit = {
        Description = "Rclone ${
          if isMount then "FUSE daemon" else "protocol serving"
        } for ${remoteName}:${sidecarPath}";
        Requires = [ "rclone-config.service" ];
        After = [ "rclone-config.service" ];
      };

      Service = {
        Type =
          if sidecarType == "serve" && !(builtins.elem sidecar.protocol serveProtocolNotifies) then
            "simple"
          else
            "notify";
        Environment =
          (lib.optional (sidecarType == "mounts") "PATH=/run/wrappers/bin")
          ++ lib.optional (sidecar.logLevel != null) "RCLONE_LOG_LEVEL=${sidecar.logLevel}";
        SuccessExitStatus = "143";

        ExecStartPre = lib.mkIf isMount "${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg sidecar.mountPoint}";
        ExecStart = lib.concatStringsSep " " (
          [ "${lib.getExe cfg.package} ${cmdName}" ]
          ++ (
            if isMount then
              [
                (lib.cli.toCommandLineShellGNU { } sidecar.options)
                (lib.escapeShellArg "${remoteName}:${sidecarPath}")
                (lib.escapeShellArg sidecar.mountPoint)
              ]
            else
              [
                (lib.escapeShellArg sidecar.protocol)
                (lib.cli.toCommandLineShellGNU { } sidecar.options)
                (lib.escapeShellArg "${remoteName}:${sidecarPath}")
              ]
          )
        );
        Restart = "on-failure";
      };

      Install.WantedBy = lib.optional (
        if isMount then sidecar.autoMount else sidecar.autoStart
      ) "default.target";
    };

  # Iterate cfg.remotes × remote.${sidecarType}, applying the supplied
  # value builder. Produces an attrset keyed by service name.
  mkRcloneSidecars =
    sidecarType: mkValue:
    lib.listToAttrs (
      lib.concatMap (
        _remote:
        let
          remoteName = _remote.name;
          remote = _remote.value;
        in
        lib.concatMap (
          _sidecar:
          let
            sidecarPath = _sidecar.name;
            sidecar = _sidecar.value;
            isMount = sidecarType == "mounts";
            cmdName = if isMount then "mount" else "serve";
          in
          lib.optional sidecar.enable (
            lib.nameValuePair "rclone-${cmdName}:${replaceIllegalChars sidecarPath}@${remoteName}" (
              mkValue {
                inherit
                  sidecarType
                  remoteName
                  sidecar
                  sidecarPath
                  isMount
                  cmdName
                  ;
              }
            )
          )
        ) (lib.attrsToList (remote.${sidecarType} or { }))
      ) (lib.attrsToList cfg.remotes)
    );

in
{
  meta.maintainers = with lib.maintainers; [ jess ];

  imports = [
    (lib.mkRemovedOptionModule [ "programs" "rclone" "writeAfter" ] ''
      The writeAfter option has been removed because rclone configuration is now handled by a
      systemd service instead of an activation script.

      For most users, no manual configuration is needed as the following secret provisioners are
      automatically detected:
       - agenix users: automatically uses agenix.service
       - sops-nix users: automatically uses sops-nix.service

      If you need custom service dependencies, use the requiresUnit option instead:
      programs.rclone.requiresUnit = "your-service-name.service";
    '')
  ];

  options = {
    programs.rclone = {
      enable = lib.mkEnableOption "rclone";

      package = lib.mkPackageOption pkgs "rclone" { };

      remotes = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              config = lib.mkOption {
                type =
                  with lib.types;
                  let
                    baseType = attrsOf (
                      nullOr (oneOf [
                        bool
                        int
                        float
                        str
                      ])
                    );

                    # Should we verify whether type constitutes a valid remote?
                    remoteConfigType = addCheck baseType (lib.hasAttr "type") // {
                      name = "rcloneRemoteConfig";
                      description = "An attribute set containing a remote type and options.";
                    };
                  in
                  remoteConfigType;
                default = { };
                description = ''
                  Regular configuration options as described in rclone's documentation
                  <https://rclone.org/docs/>. When specifying options follow the formatting
                  process outlined here <https://rclone.org/docs/#config-config-file>, namely:
                   - Remove the leading double-dash (--) from the rclone option name
                   - Replace hyphens (-) with underscores (_)
                   - Convert to lowercase
                   - Use the resulting string as your configuration key

                  For example, the rclone option "--mega-hard-delete" would use "hard_delete"
                  as the config key.

                  Security Note: Always use the {option}`secrets` option for sensitive data
                  instead of the {option}`config` option to prevent exposing credentials to
                  the world-readable Nix store.
                '';
                example = lib.literalExpression ''
                  {
                    type = "mega"; # Required - specifies the remote type
                    user = "you@example.com";
                    hard_delete = true;
                  }'';
              };

              secrets = lib.mkOption {
                type = with lib.types; attrsOf str;
                default = { };
                description = ''
                  Sensitive configuration values such as passwords, API keys, and tokens. These
                  must be provided as file paths to the secrets, which will be read at activation
                  time.

                  These values are expanded in a shell context within a systemd service, so
                  you can use bash features like command substitution or variable expansion
                  (e.g. "''${XDG_RUNTIME_DIR}" as used by agenix).
                '';
                example = lib.literalExpression ''
                  {
                    password = "/run/secrets/password";
                    api_key = config.age.secrets.api-key.path;
                  }'';
              };

              mounts = lib.mkOption {
                type =
                  with lib.types;
                  attrsOf (
                    lib.types.submodule {
                      options = {
                        enable = lib.mkEnableOption "this mount";

                        autoMount = lib.mkEnableOption "automatically mounting the remote on login" // {
                          default = true;
                        };

                        mountPoint = lib.mkOption {
                          type = lib.types.str;
                          default = null;
                          description = ''
                            A local file path specifying the location of the mount point.
                          '';
                          example = "/home/alice/my-remote";
                        };
                      }
                      // mountServeOptions;
                    }
                  );
                default = { };
                description = ''
                  An attribute set mapping remote file paths to their corresponding mount
                  point configurations.

                  For each entry, to perform the equivalent of
                  `rclone mount remote:path/to/files /path/to/local/mount` — as described in the
                  rclone documentation <https://rclone.org/commands/rclone_mount/> — we create
                  a key-value pair like this:
                  `"path/to/files/on/remote" = { ... }`.
                '';
                example = lib.literalExpression ''
                  {
                    "path/to/files" = {
                      enable = true;
                      mountPoint = "/home/alice/rclone-mount";
                      options = {
                        dir-cache-time = "5000h";
                        poll-interval = "10s";
                        umask = "002";
                        user-agent = "Laptop";
                      };
                    };
                  }
                '';

              };

              serve = lib.mkOption {
                type =
                  with lib.types;
                  attrsOf (
                    lib.types.submodule {
                      options = {
                        enable = lib.mkEnableOption "serving this path";

                        protocol = lib.mkOption {
                          type = lib.types.enum [
                            "dlna"
                            "docker"
                            "ftp"
                            "http"
                            "nfs"
                            "restic"
                            "s3"
                            "sftp"
                            "webdav"
                          ];
                          description = ''
                            The protocol to use when serving this path.
                            See <https://rclone.org/commands/rclone_serve> for more.
                          '';
                          example = "http";
                        };

                        autoStart = lib.mkEnableOption "automatically serving the remote on login" // {
                          default = true;
                        };
                      }
                      // mountServeOptions;
                    }
                  );
                default = { };
                description = ''
                  An attribute set mapping remote file paths to their corresponding serve configurations.

                  For each entry, to perform the equivalent of
                  `rclone serve protocol remote:path/to/files` — as described in the
                  rclone documentation <https://rclone.org/commands/rclone_serve/> — we create
                  a key-value pair like this:
                  `"path/to/files/on/remote" = { ... }`.
                '';
                example = lib.literalExpression ''
                  {
                    "path/to/files" = {
                      enable = true;
                      protocol = "http";
                      options = {
                        addr = "127.0.0.1:3000";
                        dir-cache-time = "5000h";
                        poll-interval = "10s";
                        umask = "002";
                        user-agent = "Laptop";
                      };
                    };
                  }
                '';
              };
            };
          }
        );
        default = { };
        description = ''
          An attribute set of remote configurations. Each remote consists of regular
          configuration options and optional secrets.

          See <https://rclone.org/docs/> for more information on configuring specific
          remotes.
        '';
        example = lib.literalExpression ''
          {
            b2 = {
              config = {
                type = "b2";
                hard_delete = true;
              };
              secrets = {
                # using sops
                account = config.sops.secrets.b2-acc-id.path;
                # using agenix
                key = config.age.secrets.b2-key.path;
              };
            };

            server.config = {
              type = "sftp";
              host = "server";
              user = "backup";
              key_file = "''${home.homeDirectory}/.ssh/id_ed25519";
            };
          }'';
      };

      requiresUnit = lib.mkOption {
        type = with lib.types; nullOr str;
        default =
          lib.foldlAttrs
            (
              acc: prov: svc:
              if isUsingSecretProvisioner prov then svc else acc
            )
            null
            {
              "sops" = "sops-nix.service";
              "age" = "agenix.service";
            };
        example = "agenix.service";
        description = ''
          The name of a systemd user service that must complete before the rclone
          configuration file is written.

          This is typically used when secrets are managed by an external provisioner
          whose service must run before the secrets are accessible.

          When using sops-nix or agenix, this value is set automatically to
          sops-nix.service or agenix.service, respectively. Set this manually if you
          use a different secret provisioner.
        '';
      };
    };
  };

  config =
    let
      rcloneConfigService =
        let
          safeConfig = lib.pipe cfg.remotes [
            (lib.mapAttrs (_: v: v.config))
            (iniFormat.generate "rclone.conf@pre-secrets")
          ];

          injectSecret =
            remote:
            lib.mapAttrsToList (secret: secretFile: ''
              if [[ ! -r "${secretFile}" ]]; then
                echo "Secret \"${secretFile}\" not found"
                cleanup
              fi

              if ! ${lib.getExe cfg.package} config update \
                     ${remote.name} config_refresh_token=false \
                     ${secret}="$(cat "${secretFile}")" \
                     --non-interactive; then
                echo "Failed to inject secret \"${secretFile}\""
                cleanup
              fi
            '') remote.value.secrets or { };

          injectAllSecrets = lib.concatMap injectSecret (lib.mapAttrsToList lib.nameValuePair cfg.remotes);
          rcloneConfigPath = "${config.xdg.configHome}/rclone/rclone.conf";
        in
        lib.mkIf (cfg.remotes != { }) {
          rclone-config = {
            Unit = lib.mkMerge [
              {
                Description = "Install rclone configuration to ${rcloneConfigPath}";
              }

              (lib.optionalAttrs (cfg.requiresUnit != null) {
                Requires = [ cfg.requiresUnit ];
                After = [ cfg.requiresUnit ];
              })
            ];

            Service = {
              Type = "oneshot";
              ExecStart = lib.getExe (
                pkgs.writeShellApplication {
                  name = "rclone-config";

                  runtimeInputs = [
                    pkgs.coreutils
                  ];

                  text = ''
                    configPath="${rcloneConfigPath}"
                    configName="$(basename $configPath)"
                    savedConfigPath="$(dirname $configPath)"/."$configName".orig

                    cleanup() {
                      echo "Failed to render config."
                      if [ -f "$savedConfigPath" ]; then
                        cp -v "$savedConfigPath" "${rcloneConfigPath}"
                      fi
                      exit 1
                    }

                    trap cleanup SIGINT

                    if [ -f "${rcloneConfigPath}" ]; then
                      cp -v "${rcloneConfigPath}" "$savedConfigPath"
                    fi

                    install -v -D -m600 "${safeConfig}" "${rcloneConfigPath}"
                    ${lib.concatLines injectAllSecrets}
                  '';
                }
              );
              Restart = "on-abnormal";
            };

            Install.WantedBy = [ "default.target" ];
          };
        };
    in
    lib.mkIf cfg.enable {
      home.packages = [ cfg.package ];
      systemd.user.services = lib.mkMerge [
        rcloneConfigService
        (mkRcloneSidecars "mounts" mkSystemdSidecar)
        (mkRcloneSidecars "serve" mkSystemdSidecar)
      ];
    };
}
