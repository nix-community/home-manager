{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.kanata;

  # Merge `default` into the keyboard map so we can iterate over both uniformly.
  allKeyboards = cfg.keyboards // lib.optionalAttrs (cfg.default != null) { default = cfg.default; };

  effectiveConfigFile =
    name: kbd:
    if kbd.configFile != null then
      toString kbd.configFile
    else
      "${config.xdg.configHome}/kanata/${name}.kbd";

  mkExecStart =
    name: kbd:
    lib.concatStringsSep " " (
      [
        (lib.getExe cfg.package)
        "--cfg"
        (effectiveConfigFile name kbd)
        "--nodelay"
        "--no-wait"
        "--symlink-path"
        kbd.symlinkPath
      ]
      ++ lib.optionals (kbd.port != null) [
        "--port"
        (toString kbd.port)
      ]
      ++ kbd.extraArgs
    );

in
{
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {

    # Ensure the directory kanata writes its virtual-device symlinks into exists.
    systemd.user.tmpfiles.rules = [
      "d ${config.xdg.stateHome}/kanata 0750 - - - -"
    ];

    systemd.user.services = lib.mapAttrs' (
      name: kbd:
      lib.nameValuePair "kanata-${name}" {
        Unit = {
          Description = "kanata keyboard remapper — ${name}";
          Documentation = [ "https://github.com/jtroo/kanata" ];
          After = lib.optional (kbd.port != null) "network.target";
        };

        Service = {
          ExecStart = mkExecStart name kbd;
          Restart = "on-failure";
          RestartSec = 3;

          # Harden to the max: grant only the two device classes kanata needs.
          # The user must be in the `input` and `uinput` groups so the
          # kernel honours the DeviceAllow entries below.
          CapabilityBoundingSet = "";
          DeviceAllow = [
            "/dev/uinput rw"
            "char-input r"
          ];
          DevicePolicy = "closed";
          IPAddressDeny = [ "any" ];
          IPAddressAllow = lib.optional (kbd.port != null) "localhost";
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          NoNewPrivileges = true;
          PrivateNetwork = kbd.port == null;
          PrivateTmp = true;
          ProcSubset = "pid";
          ProtectClock = true;
          ProtectHostname = true;
          ProtectKernelLogs = true;
          ProtectProc = "invisible";
          RestrictAddressFamilies = [ "AF_UNIX" ] ++ lib.optional (kbd.port != null) "AF_INET";
          RestrictNamespaces = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          SystemCallArchitectures = [ "native" ];
          SystemCallFilter = [
            "@system-service"
            "~@privileged"
            "~@resources"
          ];
          UMask = "0077";
        };

        Install.WantedBy = [ "default.target" ];
      }
    ) allKeyboards;

  };
}
