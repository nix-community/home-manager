{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.tea;

  settingsFormat = pkgs.formats.yaml { };

  placeholderFor = login: "___HM_TEA_TOKEN_${lib.replaceStrings [ "." ] [ "_" ] login.name}___";

  loginModule = lib.types.submodule {
    options = {
      default = lib.mkOption {
        default = false;
        description = "Whether this is the default login.";
        type = lib.types.bool;
      };

      insecure = lib.mkOption {
        default = false;
        description = "Skip TLS certificate verification.";
        type = lib.types.bool;
      };

      name = lib.mkOption {
        description = "Name of this login entry.";
        type = lib.types.str;
      };

      ssh = lib.mkOption {
        default = null;
        description = "SSH configuration for Git operations.";

        type = lib.types.nullOr (
          lib.types.submodule {
            options = {
              agent = lib.mkOption {
                default = false;
                description = "Whether to use the SSH agent.";
                type = lib.types.bool;
              };

              host = lib.mkOption {
                description = "SSH host for Git operations.";
                type = lib.types.str;
              };

              key = lib.mkOption {
                description = "Path to the SSH private key.";
                type = lib.types.str;
              };
            };
          }
        );
      };

      token = lib.mkOption {
        default = "";

        description = ''
          API token for authentication. Note that this value is written to
          the Nix store. Use {option}`tokenFile` to avoid storing secrets
          in the Nix store.
        '';

        type = lib.types.str;
      };

      tokenFile = lib.mkOption {
        default = null;

        description = ''
          Path to a file containing the API token. The file contents are
          read at activation time and substituted into the generated
          configuration. This avoids storing secrets in the Nix store.
        '';

        type = lib.types.nullOr lib.types.path;
      };

      url = lib.mkOption {
        description = "URL of the Gitea or Forgejo instance.";
        type = lib.types.str;
      };

      user = lib.mkOption {
        default = null;
        description = "Username for this login.";
        type = lib.types.nullOr lib.types.str;
      };

      versionCheck = lib.mkOption {
        default = false;
        description = "Check for newer versions of tea.";
        type = lib.types.bool;
      };
    };
  };

  hasTokenFile = login: login.tokenFile != null;
  anyTokenFile = lib.any hasTokenFile cfg.logins;
in
{
  meta.maintainers = [ lib.maintainers.opdavies ];

  options.programs.tea = {
    enable = lib.mkEnableOption "tea, a Gitea/Forgejo CLI";

    logins = lib.mkOption {
      default = [ ];
      description = "Gitea/Forgejo login configurations.";
      type = lib.types.listOf loginModule;
    };

    package = lib.mkPackageOption pkgs "tea" { nullable = true; };

    preferences = lib.mkOption {
      inherit (settingsFormat) type;

      default = { };
      description = "Preferences written to {file}`config.yml`.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
      }

      (lib.mkIf (cfg.logins != [ ] || cfg.preferences != { }) {
        xdg.configFile."tea/config.yml" = {
          source = settingsFormat.generate "tea-config" {
            inherit (cfg) preferences;

            logins = map (
              login:
              lib.filterAttrs (_: v: v != null) (
                {
                  inherit (login)
                    default
                    insecure
                    name
                    url
                    user
                    ;

                  token = if login.tokenFile != null then placeholderFor login else login.token;
                  version_check = login.versionCheck;
                }
                // lib.optionalAttrs (login.ssh != null) {
                  ssh_agent = login.ssh.agent;
                  ssh_host = login.ssh.host;
                  ssh_key = login.ssh.key;
                }
              )
            ) cfg.logins;
          };
        };
      })

      (lib.mkIf anyTokenFile {
        home.activation.teaBackupCleanup = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          rm -f "${config.xdg.configHome}/tea/config.yml.backup"
        '';

        home.activation.teaToken =
          let
            substitutions = lib.concatMapStrings (
              login:
              lib.optionalString (login.tokenFile != null) ''
                if [[ -r "${login.tokenFile}" ]]; then
                  token=$(cat "${login.tokenFile}")
                  tmpFile="$configFile.tmp.$$$PPID"
                  while IFS= read -r line || [[ -n "$line" ]]; do
                    printf '%s\n' "''${line//${placeholderFor login}/$token}"
                  done < "$configFile" > "$tmpFile"
                  mv "$tmpFile" "$configFile"
                fi
              ''
            ) cfg.logins;
          in
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            configFile="${config.xdg.configHome}/tea/config.yml"
            if [[ -L "$configFile" ]]; then
              target=$(readlink "$configFile")
              rm "$configFile"
              cp "$target" "$configFile"
              chmod 600 "$configFile"
            fi
            ${substitutions}
          '';
      })
    ]
  );
}
