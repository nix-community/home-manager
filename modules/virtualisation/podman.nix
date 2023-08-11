{ config, lib, pkgs, ... }:

let
  cfg = config.virtualisation.podman;
  toml = pkgs.formats.toml { };
  json = pkgs.formats.json { };

  inherit (lib) mkDefault mkIf mkMerge mkOption types;

  podmanPackage = (pkgs.podman.override { inherit (cfg) extraPackages; });

  # Provides a fake "docker" binary mapping to podman
  dockerAlias = pkgs.runCommandNoCC
    "${podmanPackage.pname}-docker-alias-${podmanPackage.version}" {
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

  podmactl = import (pkgs.fetchFromGitHub {
    owner = "michaelCTS";
    repo = "podmactl";
    rev = "v0.0.4";
    hash = "sha256-7lMOcJZDkNSqBNXxI9iE0yn+hHhEwrWykS+C02NSQCk=";
  }) { };

  machineOpts = {
    # Options here are loaded into python. For simplicity, please use
    # snake_case.
    options = {
      active = mkOption {
        type = types.bool;
        default = false;
        description = ''
          This machine should be started. Only one machine can be active at a time
        '';
      };

      qemu_binary = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "''${pkgs.qemu}/bin/qemu-system-x86_64";
        description = ''
          Use this to start VM with the qemu appropriate for your architecture.
        '';
      };

      # Options passed to Podman machine.
      # See https://docs.podman.io/en/latest/markdown/podman-machine.1.html
      cpus = mkOption {
        type = types.ints.positive;
        default = 1;
        description = "The number of CPUs to assign to the VM.";
      };

      disk_size = mkOption {
        type = types.ints.positive;
        default = 100;
        description = "Size of disk in gigabytes. Can only be increased";
      };

      image_path = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = lib.literalExpression ''
          builtins.fetchurl "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/38.20230819.3.0/x86_64/fedora-coreos-38.20230819.3.0-qemu.x86_64.qcow2.xz"'';
        description = ''
          Image to be used when starting the VM
          Can be a local path or a URL to an image.
          Alternatives can be found at <https://fedoraproject.org/en/coreos/download>.
        '';
      };

      memory = mkOption {
        type = types.ints.positive;
        default = 2048;
        description = "RAM in MB to be assigned to the machine";
      };
    };
  };

in {
  meta.maintainers = [ pkgs.lib.maintainers.michaelCTS ];

  options.virtualisation.podman = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        This option enables Podman, a daemonless container engine for
        developing, managing, and running OCI Containers on your Linux System.

        It is a drop-in replacement for the {command}`docker` command.
      '';
    };

    enableDockerSocket = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Make the Podman socket available in place of the Docker socket, so
        Docker tools can find the Podman socket.

        Podman implements the Docker API.
      '';
    };

    enableDockerAlias = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Create an alias mapping {command}`docker` to {command}`podman`.
      '';
    };

    extraPackages = mkOption {
      type = with types; listOf package;
      default = [ ];
      example = lib.literalExpression "[ pkgs.gvisor ]";
      description = ''
        Extra packages to be installed in the Podman wrapper.
      '';
    };

    finalPackage = lib.mkOption {
      type = types.package;
      internal = true;
      readOnly = true;
      default = podmanPackage;
      description = ''
        The final Podman package (including extra packages).
      '';
    };

    defaultNetwork.extraPlugins = lib.mkOption {
      type = types.listOf json.type;
      default = [ ];
      description = ''
        Extra CNI plugin configurations to add to Podman's default network.
      '';
    };

    machines = lib.mkOption {
      type = types.attrsOf (types.submodule machineOpts);
      # One and only one machine may be active at any given time
      apply = machines:
        assert ((lib.lists.count (machine: machine.active)
          (lib.attrsets.attrValues machines)) == 1);
        machines;
      default = {
        podman-machine-default = {
          active = true;
          cpus = 2;
          disk_size = 100;
          memory = 2048;
        };
      };
      example = lib.literalExpression ''
        {
          intel-x86 = {
            cpus = 2;
            disk_size = 200;
            memory = 4096;
            image_path = "fedora-coreos-38.20230806.3.0-qemu.x86_64.qcow2.xz";
            qemu_binary = "${pkgs.qemu}/bin/qemu-system-x86_64";
          };
        }
      '';
      description = ''
        Virtual machine descriptions when Podman is run in on non-Linux systems.
      '';
    };

  };

  config = mkIf cfg.enable (mkMerge [
    {
      home.packages = [ cfg.finalPackage ]
        ++ lib.optional cfg.enableDockerAlias dockerAlias;

      virtualisation.containers = {
        enable = true; # Enable common /etc/containers configuration
      };
    }

    (mkIf pkgs.stdenv.hostPlatform.isLinux (mkMerge [
      {
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
              ExecStart = [
                "${cfg.finalPackage}/bin/podman"
                "$LOGGING"
                "system"
                "service"
              ];
            };

            Install = { WantedBy = [ "default.target" ]; };
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

      (mkIf cfg.enableDockerSocket {
        home.sessionVariables."DOCKER_HOST" =
          "unix:///$XDG_RUNTIME_DIR/podman/podman.sock";
      })
    ]))

    (mkIf pkgs.stdenv.isDarwin (mkMerge [
      {
        home.packages = [
          pkgs.qemu # To manage machines
          pkgs.openssh # To ssh into the machines
        ];
      }

      {
        home.extraActivationPath = [
          pkgs.qemu # To manage machines.
          pkgs.openssh # To ssh into the machines.
        ];

        # CRUD the requested podman machines when activating the profile
        home.activation.podman-machine =
          lib.hm.dag.entryAfter [ "writeBoundary" ]
          (lib.strings.concatStringsSep " " [
            "$DRY_RUN_CMD"
            "${podmactl}/bin/podmactl"
            "--podman"
            "${cfg.finalPackage}/bin/podman"
            "$VERBOSE_ARG"
            "${json.generate "podman-machines.json" cfg.machines}"
          ]);
      }

      # Socket is actually only available after the launchd agent has
      # successfully completed and the machine has been started.
      (mkIf cfg.enableDockerSocket {
        home.sessionVariables."DOCKER_HOST" =
          "unix:///Users/$USER/.local/share/containers/podman/machine/qemu/podman.sock";
      })
    ]))
  ]);
}
