{ config, lib, pkgs, ... }:
let
  cfg = config.services.podman;
  toml = pkgs.formats.toml { };
  json = pkgs.formats.json { };

  inherit (lib) mkOption types;

  podmanPackage = (pkgs.podman.override { inherit (cfg) extraPackages; });

  # Provides a fake "docker" binary mapping to podman
  dockerCompat = pkgs.runCommandNoCC
    "${podmanPackage.pname}-docker-compat-${podmanPackage.version}" {
      outputs = [ "out" "man" ];
      inherit (podmanPackage) meta;
    } ''
      mkdir -p $out/bin
      ln -s ${podmanPackage}/bin/podman $out/bin/docker

      mkdir -p $man/share/man/man1
      for f in ${podmanPackage.man}/share/man/man1/*; do
        basename=$(basename $f | sed s/podman/docker/g)
        ln -s $f $man/share/man/man1/$basename
      done
    '';

  net-conflist = pkgs.runCommand "87-podman-bridge.conflist" {
    nativeBuildInputs = [ pkgs.jq ];
    extraPlugins = builtins.toJSON cfg.defaultNetwork.extraPlugins;
    jqScript = ''
      . + { "plugins": (.plugins + $extraPlugins) }
    '';
  } ''
    jq <${cfg.package}/etc/cni/net.d/87-podman-bridge.conflist \
      --argjson extraPlugins "$extraPlugins" \
      "$jqScript" \
      >$out
  '';

in {
  meta.maintainers = [ lib.maintainers.bad ];
  imports = [
    ./podman-dnsname.nix
    #./podman-network-socket.nix
    (lib.mkRenamedOptionModule [ "virtualisation" "podman" "libpod" ] [
      "virtualisation"
      "containers"
      "containersConf"
    ])
  ];

  options.services.podman = {

    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        This option enables Podman, a daemonless container engine for
        developing, managing, and running OCI Containers on your Linux System.

        It is a drop-in replacement for the <command>docker</command> command.
      '';
    };

    dockerSocket = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Make the Podman socket available in place of the Docker socket, so
        Docker tools can find the Podman socket.

        Podman implements the Docker API.
      '';
    };

    dockerCompat = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Create an alias mapping <command>docker</command> to <command>podman</command>.
      '';
    };

    enableNvidia = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Enable use of NVidia GPUs from within podman containers.
      '';
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = lib.literalExample ''
        [
          pkgs.gvisor
        ]
      '';
      description = ''
        Extra packages to be installed in the Podman wrapper.
      '';
    };

    package = lib.mkOption {
      type = types.package;
      default = podmanPackage;
      internal = true;
      description = ''
        The final Podman package (including extra packages).
      '';
    };

    defaultNetwork.extraPlugins = lib.mkOption {
      type = types.listOf json.type;
      default = [ ];
      description = ''
        Extra CNI plugin configurations to add to podman's default network.
      '';
    };

  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    {
      home.packages = [ cfg.package ]
        ++ lib.optional cfg.dockerCompat dockerCompat;

      xdg.configFile."cni/net.d/87-podman-bridge.conflist".source =
        net-conflist;

      virtualisation.containers = {
        enable = true; # Enable common /etc/containers configuration
        containersConf.settings = lib.optionalAttrs cfg.enableNvidia {
          engine = {
            conmon_env_vars =
              [ "PATH=${lib.makeBinPath [ pkgs.nvidia-podman ]}" ];
            runtimes.nvidia =
              [ "${pkgs.nvidia-podman}/bin/nvidia-container-runtime" ];
          };
        };
      };

      systemd.user = {

        services.podman = {
          Unit = {
            Description = "Podman API Service";
            Requires = "podman.socket";
            After = "podman.socket";
            Documentation = "man:podman-system-service(1)";
            StartLimitIntervalSec = 0;
          };
          Service = {
            Type = "exec";
            KillMode = "process";
            Environment = ''LOGGING=" --log-level=info"'';
            ExecStart =
              [ "" "${cfg.package}/bin/podman $LOGGING system service" ];
          };

          Install = { WantedBy = [ "multi-user.target" ]; };
        };

        sockets.podman = {
          Unit = {
            Description = "Podman API Socket";
            Documentation = "man:podman-system-service(1)";
          };
          Socket = {
            ListenStream = "%t/podman/podman.sock";
            SocketMode = 660;
          };
          Install.WantedBy = [ "sockets.target" ];
        };

      };
    }
    (lib.mkIf cfg.dockerSocket {
      home.sessionVariables."DOCKER_HOST" =
        "unix:///run/user/$UID/podman/podman.sock";
    })
  ]);
}
