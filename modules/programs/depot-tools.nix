{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.depot-tools;

  isUsingSecretProvisioner = name: config ? "${name}" && config."${name}".secrets != { };

  envVarNameRegex = "[A-Za-z_][A-Za-z0-9_]*";

  shellEnvFile = "${config.xdg.configHome}/depot-tools/environment";

  renderEnvironmentLine = name: value: ''
    value=${lib.escapeShellArg value}
    printf -v quoted '%q' "$value"
    printf 'export ${name}=%s\n' "$quoted"
  '';

  renderSecretLine = name: path: ''
    secret_file=${lib.escapeShellArg path}
    if [[ ! -r "$secret_file" ]]; then
      echo "Secret file for ${name} is not readable: $secret_file" >&2
      exit 1
    fi
    value="$(cat "$secret_file")"
    printf -v quoted '%q' "$value"
    printf 'export ${name}=%s\n' "$quoted"
  '';

  environmentScript = pkgs.writeShellApplication {
    name = "depot-tools-environment";
    runtimeInputs = [ pkgs.coreutils ];
    text = ''
      set -euo pipefail

      env_file="${shellEnvFile}"
      install -d -m 700 "$(dirname "$env_file")"
      tmp_file="$(mktemp "$env_file.tmp.XXXXXX")"
      trap 'rm -f "$tmp_file"' EXIT

      umask 077
      {
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList renderEnvironmentLine cfg.environment)}
      ${lib.concatStringsSep "\n" (lib.mapAttrsToList renderSecretLine cfg.environmentSecretFiles)}
      } > "$tmp_file"

      install -m 600 "$tmp_file" "$env_file"
    '';
  };

in
{
  meta.maintainers = with lib.maintainers; [ caniko ];

  options.programs.depot-tools = {
    enable = lib.mkEnableOption "Chromium depot_tools";

    package = lib.mkPackageOption pkgs "depot-tools" { };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        DEPOT_TOOLS_METRICS = "0";
      };
      description = ''
        Non-secret environment variables to expose to depot_tools commands.
      '';
    };

    environmentSecretFiles = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = lib.literalExpression ''
        {
          GIT_COOKIES_PATH = config.age.secrets.chromium-git-cookies.path;
          LUCI_CONTEXT = config.age.secrets.luci-context.path;
        }
      '';
      description = ''
        Environment variables whose values are read from files at service run time.

        This is suitable for secrets managed by agenix, sops-nix, or another
        provisioner that writes files outside the Nix store.
      '';
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
        Systemd user service that must complete before depot_tools secret
        environment variables are rendered.

        This is inferred automatically for agenix and sops-nix users.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        assertions =
          lib.mapAttrsToList (name: _value: {
            assertion = builtins.match envVarNameRegex name != null;
            message = "programs.depot-tools.environment contains invalid environment variable name: ${name}";
          }) cfg.environment
          ++ lib.mapAttrsToList (name: _value: {
            assertion = builtins.match envVarNameRegex name != null;
            message = "programs.depot-tools.environmentSecretFiles contains invalid environment variable name: ${name}";
          }) cfg.environmentSecretFiles
          ++ [
            {
              assertion = cfg.environmentSecretFiles == { } || pkgs.stdenv.hostPlatform.isLinux;
              message = "programs.depot-tools.environmentSecretFiles currently requires systemd user services, which are only available on Linux.";
            }
          ];

        home.packages = [ cfg.package ];
        home.sessionVariables = cfg.environment;
      }

      (lib.mkIf (cfg.environmentSecretFiles != { }) {
        systemd.user.services.depot-tools-environment = {
          Unit = lib.mkMerge [
            {
              Description = "Render depot_tools environment";
            }
            (lib.optionalAttrs (cfg.requiresUnit != null) {
              Requires = [ cfg.requiresUnit ];
              After = [ cfg.requiresUnit ];
            })
          ];

          Service = {
            Type = "oneshot";
            ExecStart = lib.getExe environmentScript;
          };

          Install.WantedBy = [ "default.target" ];
        };

        programs.bash.initExtra = lib.mkAfter ''
          if [ -r "${shellEnvFile}" ]; then
            . "${shellEnvFile}"
          fi
        '';

        programs.zsh.initContent = lib.mkAfter ''
          if [ -r "${shellEnvFile}" ]; then
            . "${shellEnvFile}"
          fi
        '';
      })
    ]
  );
}
