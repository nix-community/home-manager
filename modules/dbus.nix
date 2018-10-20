{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.dbus;
  dag = config.lib.dag;
in
{
  meta.maintainers = [ maintainers.gnidorah ];

  options = {
    dbus.activation = mkOption {
      default = {};
      type = types.attrs;
      description = ''
        Activation scripts for the home environment involving dbus.
        </para><para>
        If dbus user service if available then it will be used,
        otherwise home-manager activation will be used. Helps with
        case when home-manager is used as NixOS module.
        Same rules apply as for <option>home.activation</option>.
      '';
    };
  };

  config = {
    systemd.user.services = mapAttrs (n: v:
      let
        script = pkgs.writeShellScriptBin n v;
      in
      {
        Unit = {
          Description = n;
          Requires = [ "dbus.socket" ];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${script}/bin/${n}";
        };
      }
    ) cfg.activation;

    home.activation = mapAttrs (n: v:
      dag.entryAfter ["reloadSystemD"] (
      let
        ensureRuntimeDir = "XDG_RUNTIME_DIR=\${XDG_RUNTIME_DIR:-/run/user/$(id -u)}";
      in
      ''
        if ${ensureRuntimeDir} ${config.systemd.user.systemctlPath} --quiet --user start dbus 2> /dev/null; then
          echo "dbus module: starting user service for ${n}"
          ${ensureRuntimeDir} ${config.systemd.user.systemctlPath} --user start ${n}
        else
          echo "dbus module: dbus user service is not available, using home-manager activation for ${n}"
          ${v}
        fi
      ''
      )
    ) cfg.activation;
  };
}
