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

  options.services.ssh-agent = {
    enable = lib.mkEnableOption "OpenSSH private key agent";

    package = lib.mkPackageOption pkgs "openssh" { };

    socket = lib.mkOption {
      type = lib.types.str;
      default = "ssh-agent";
      example = "ssh-agent/socket";
      description = ''
        The agent's socket; interpreted as a suffix to {env}`$XDG_RUNTIME_DIR`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.ssh-agent" pkgs lib.platforms.linux)
    ];

    home.sessionVariablesExtra = ''
      if [ -z "$SSH_AUTH_SOCK" ]; then
        export SSH_AUTH_SOCK=$XDG_RUNTIME_DIR/${cfg.socket}
      fi
    '';

    systemd.user.services.ssh-agent = {
      Install.WantedBy = [ "default.target" ];
      Unit = {
        Description = "SSH authentication agent";
        Documentation = "man:ssh-agent(1)";
      };
      Service.ExecStart = "${lib.getExe' cfg.package "ssh-agent"} -D -a %t/${cfg.socket}";
    };
  };
}
