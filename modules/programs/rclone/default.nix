{
  config,
  lib,
  pkgs,
  ...
}:

let

  cfg = config.programs.rclone;
  iniFormat = pkgs.formats.ini { };
  replaceSlashes = builtins.replaceStrings [ "/" ] [ "." ];

in
{
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
                  process outlined here <https://rclone.org/docs/#config-config-file>, namley:
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

                  Note: If using secret management solutions like agenix or sops-nix with
                  home-manager, you need to ensure their services are activated before switching
                  to this home-manager generation. Consider setting
                  {option}`systemd.user.startServices` to `"sd-switch"` for automatic service
                  startup.
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

                        mountPoint = lib.mkOption {
                          type = lib.types.str;
                          default = null;
                          description = ''
                            A local file path specifying the location of the mount point.
                          '';
                          example = "/home/alice/my-remote";
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
                            cache-dir = "%C";
                          };
                          description = ''
                            An attribute set of option values passed to `rclone mount`. To set
                            a boolean option, assign it `true` or `false`. See
                            <https://nixos.org/manual/nixpkgs/stable/#function-library-lib.cli.toGNUCommandLineShell>
                            for more details on the format.

                            Some caching options are set by default, namely `vfs-cache-mode = "full"`
                            and `cache-dir`. These can be overridden if desired.
                          '';
                        };
                      };
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

      writeAfter = lib.mkOption {
        type = lib.types.str;
        default = "reloadSystemd";
        description = ''
          Controls when the rclone configuration is written during Home Manager activation.
          You should not need to change this unless you have very specific activation order
          requirements.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ cfg.package ];

      activation.createRcloneConfig =
        let
          safeConfig = lib.pipe cfg.remotes [
            (lib.mapAttrs (_: v: v.config))
            (iniFormat.generate "rclone.conf@pre-secrets")
          ];

          # https://github.com/rclone/rclone/issues/8190
          injectSecret =
            remote:
            lib.mapAttrsToList (secret: secretFile: ''
              ${lib.getExe cfg.package} config update \
                ${remote.name} config_refresh_token=false \
                ${secret} "$(cat ${secretFile})" \
                --quiet --non-interactive > /dev/null
            '') remote.value.secrets or { };

          injectAllSecrets = lib.concatMap injectSecret (lib.mapAttrsToList lib.nameValuePair cfg.remotes);
        in
        lib.mkIf (cfg.remotes != { }) (
          lib.hm.dag.entryAfter [ "writeBoundary" cfg.writeAfter ] ''
            run install $VERBOSE_ARG -D -m600 ${safeConfig} "${config.xdg.configHome}/rclone/rclone.conf"
            ${lib.concatLines injectAllSecrets}
          ''
        );
    };

    systemd.user.services = lib.listToAttrs (
      lib.concatMap
        (
          { name, value }:
          let
            remote-name = name;
            remote = value;
          in
          lib.concatMap (
            { name, value }:
            let
              mount-path = name;
              mount = value;
            in
            [
              (lib.nameValuePair "rclone-mount:${replaceSlashes mount-path}@${remote-name}" {
                Unit = {
                  Description = "Rclone FUSE daemon for ${remote-name}:${mount-path}";
                };

                Service = {
                  Environment = [
                    # fusermount/fusermount3
                    "PATH=/run/wrappers/bin"
                  ];
                  ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${mount.mountPoint}";
                  ExecStart = lib.concatStringsSep " " [
                    (lib.getExe cfg.package)
                    "mount"
                    "-vv"
                    (lib.cli.toGNUCommandLineShell { } mount.options)
                    "${remote-name}:${mount-path}"
                    "${mount.mountPoint}"
                  ];
                  Restart = "on-failure";
                };

                Install.WantedBy = [ "default.target" ];
              })
            ]
          ) (lib.attrsToList remote.mounts)
        )
        (
          lib.pipe cfg.remotes [
            lib.attrsToList
            (lib.filter (rem: rem.value ? mounts))
          ]
        )
    );
  };

  meta.maintainers = with lib.hm.maintainers; [ jess ];
}
