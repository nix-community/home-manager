{ config, pkgs, lib, ... }:

lib.mkIf config.test.enableBig {
  virtualisation.podman.enable = true;

  nmt.script = lib.mkIf pkgs.stdenv.isLinux ''
    servicePath=home-files/.config/systemd/user

    assertFileExists $servicePath/podman.service $servicePath/podman.socket

    podmanServiceNormalized="$(normalizeStorePaths "$servicePath/podman.service")"
    assertFileContent $podmanServiceNormalized \
      ${
        builtins.toFile "podman.service-expected" ''
          [Install]
          WantedBy=default.target

          [Service]
          Environment=LOGGING=" --log-level=info"
          ExecStart=/nix/store/00000000000000000000000000000000-podman/bin/podman
          ExecStart=$LOGGING
          ExecStart=system
          ExecStart=service
          KillMode=process
          Type=exec

          [Unit]
          After=podman.socket
          Description=Podman API Service
          Documentation=man:podman-system-service(1)
          Requires=podman.socket
          StartLimitIntervalSec=0
        ''
      }

    assertFileContent $servicePath/podman.socket \
      ${
        builtins.toFile "podman.socket-expected" ''
          [Install]
          WantedBy=sockets.target

          [Socket]
          ListenStream=%t/podman/podman.sock
          SocketMode=660

          [Unit]
          Description=Podman API Socket
          Documentation=man:podman-system-service(1)
        ''
      }
  '';
}
