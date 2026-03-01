{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.ssh-agent;
in
{
  meta.maintainers = [
    lib.maintainers.bmrips
    lib.hm.maintainers.lheckemann
  ];

  imports =
    map (shell: lib.mkRemovedOptionModule [ "services" "ssh-agent" "enable${shell}Integration" ] "")
      [
        "Bash"
        "Zsh"
        "Fish"
        "Nushell"
      ];

  options.services.ssh-agent = {
    enable = lib.mkEnableOption "OpenSSH private key agent";

    package = lib.mkPackageOption pkgs "openssh" { };

    socket = lib.mkOption {
      type = lib.types.str;
      default = "ssh-agent";
      example = "ssh-agent/socket";
      description = ''
        The agent's socket; interpreted as a suffix to {env}`$XDG_RUNTIME_DIR`
        on Linux and `$(getconf DARWIN_USER_TEMP_DIR)` on macOS.
      '';
    };

    defaultMaximumIdentityLifetime = lib.mkOption {
      type = lib.types.nullOr lib.types.ints.positive;
      default = null;
      example = 3600;
      description = ''
        Set a default value for the maximum lifetime in seconds of identities added to the agent.
      '';
    };

    pkcs11Whitelist = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = lib.literalExpression ''[ "''${pkgs.tpm2-pkcs11}/lib/*" ]'';
      description = ''
        Specify a list of approved path patterns for PKCS#11 and FIDO authenticator middleware libraries. When using the -s or -S options with {manpage}`ssh-add(1)`, only libraries matching these patterns will be accepted.

        See {manpage}`ssh-agent(1)`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {

    ssh_auth_sock.initialization =
      let
        socketPath =
          if pkgs.stdenv.isDarwin then
            "$(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${cfg.socket}"
          else
            "$XDG_RUNTIME_DIR/${cfg.socket}";
      in
      {
        bash = ''export SSH_AUTH_SOCK="${socketPath}"'';
        fish = ''set -x SSH_AUTH_SOCK "${socketPath}"'';
        nushell = "$env.SSH_AUTH_SOCK = ${
          if pkgs.stdenv.isDarwin then
            ''$"(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${cfg.socket}"''
          else
            ''$"($env.XDG_RUNTIME_DIR)/${cfg.socket}"''
        }";
      };

    systemd.user.services.ssh-agent = {
      Install.WantedBy = [ "default.target" ];
      Unit = {
        Description = "SSH authentication agent";
        Documentation = "man:ssh-agent(1)";
      };
      Service.ExecStart = "${lib.getExe' cfg.package "ssh-agent"} -D -a %t/${cfg.socket}${
        lib.optionalString (
          cfg.defaultMaximumIdentityLifetime != null
        ) " -t ${toString cfg.defaultMaximumIdentityLifetime}"
      }${
        lib.optionalString (
          cfg.pkcs11Whitelist != [ ]
        ) " -P '${lib.concatStringsSep "," cfg.pkcs11Whitelist}'"
      }";
    };

    launchd.agents.ssh-agent = {
      enable = true;
      config = {
        ProgramArguments = [
          (lib.getExe pkgs.bash)
          "-c"
          ''${lib.getExe' cfg.package "ssh-agent"} -D -a "$(${lib.getExe pkgs.getconf} DARWIN_USER_TEMP_DIR)/${cfg.socket}"${
            lib.optionalString (
              cfg.defaultMaximumIdentityLifetime != null
            ) " -t ${toString cfg.defaultMaximumIdentityLifetime}"
          }${
            lib.optionalString (
              cfg.pkcs11Whitelist != [ ]
            ) " -P '${lib.concatStringsSep "," cfg.pkcs11Whitelist}'"
          }''
        ];
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        ProcessType = "Background";
        RunAtLoad = true;
      };
    };
  };
}
