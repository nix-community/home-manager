{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.services.colima;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [
    lib.hm.maintainers.will-lol
  ];

  options.services.colima = {
    enable = mkEnableOption "Colima, a container runtime";

    package = mkPackageOption pkgs "colima" { };

    addDockerContext = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to add a Docker context for Colima.";
    };

    useAsDefaultContext = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to set Colima docker context as default";
    };

    logFile = mkOption {
      type = types.path;
      default = "${config.home.homeDirectory}/.local/state/colima.log";
      defaultText = lib.literalExpression "\${config.home.homeDirectory}/.local/state/colima.log";
      description = "Combined stdout and stderr log file for the Colima service.";
    };

    settings = mkOption {
      type = types.submodule {
        freeformType = yamlFormat.type;
        options = {
          cpu = mkOption {
            type = types.int;
            default = 2;
            description = "Number of CPUs to be allocated to the virtual machine.";
          };
          disk = mkOption {
            type = types.int;
            default = 100;
            description = "Size of the disk in GiB to be allocated to the virtual machine.";
          };
          memory = mkOption {
            type = types.int;
            default = 2;
            description = "Size of the memory in GiB to be allocated to the virtual machine.";
          };
          arch = mkOption {
            type = types.enum [
              "x86_64"
              "aarch64"
              "host"
            ];
            default = "host";
            description = "Architecture of the virtual machine.";
          };
          runtime = mkOption {
            type = types.enum [
              "docker"
              "containerd"
              "incus"
            ];
            default = "docker";
            description = "Container runtime to be used.";
          };
          hostname = mkOption {
            type = types.str;
            default = "colima";
            description = "Set custom hostname for the virtual machine.";
          };
          kubernetes = mkOption {
            type = types.submodule {
              options = {
                enabled = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Enable kubernetes.";
                };
                version = mkOption {
                  type = types.str;
                  default = "v1.33.3+k3s1";
                  description = "Kubernetes version to use.";
                };
                k3sArgs = mkOption {
                  type = types.listOf types.str;
                  default = [ "--disable=traefik" ];
                  description = "Additional args to pass to k3s.";
                };
              };
            };
            default = { };
            description = "Kubernetes configuration for the virtual machine.";
          };
          autoActivate = mkOption {
            type = types.bool;
            default = true;
            description = "Auto-activate on the Host for client access.";
          };
          network = mkOption {
            type = types.submodule {
              options = {
                address = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Assign reachable IP address to the virtual machine.";
                };
                dns = mkOption {
                  type = types.listOf types.str;
                  default = [ ];
                  description = "Custom DNS resolvers for the virtual machine.";
                };
                dnsHosts = mkOption {
                  type = types.attrsOf types.str;
                  default = { };
                  description = "DNS hostnames to resolve to custom targets.";
                };
                hostAddresses = mkOption {
                  type = types.bool;
                  default = false;
                  description = "Replicate host IP addresses in the VM.";
                };
              };
            };
            default = { };
            description = "Network configurations for the virtual machine.";
          };
          forwardAgent = mkOption {
            type = types.bool;
            default = false;
            description = "Forward the host's SSH agent to the virtual machine.";
          };
          docker = mkOption {
            type = types.attrs;
            default = { };
            description = "Docker daemon configuration.";
          };
          vmType = mkOption {
            type = types.enum [
              "qemu"
              "vz"
            ];
            default = if pkgs.stdenv.isDarwin then "vz" else "qemu";
            defaultText = lib.literalExpression "\${if pkgs.stdenv.isDarwin then \"vz\" else \"qemu\"}";
            description = "Virtual Machine type (vz only valid on macOS 13+).";
          };
          rosetta = mkOption {
            type = types.bool;
            default = false;
            description = "Utilise rosetta for amd64 emulation (Apple Silicon + vmType=vz only).";
          };
          binfmt = mkOption {
            type = types.bool;
            default = true;
            description = "Enable foreign architecture emulation via binfmt.";
          };
          nestedVirtualization = mkOption {
            type = types.bool;
            default = false;
            description = "Enable nested virtualization.";
          };
          mountType = mkOption {
            type = types.enum [
              "virtiofs"
              "9p"
              "sshfs"
            ];
            description = "Volume mount driver for the virtual machine.";
          };
          mountInotify = mkOption {
            type = types.bool;
            default = true;
            description = "Propagate inotify file events to the VM.";
          };
          cpuType = mkOption {
            type = types.str;
            default = "";
            description = "The CPU type for the virtual machine.";
          };
          provision = mkOption {
            type = types.listOf (
              types.submodule {
                options = {
                  mode = mkOption {
                    type = types.enum [
                      "system"
                      "user"
                    ];
                    description = "Mode for the provision script.";
                  };
                  script = mkOption {
                    type = types.str;
                    description = "The provision script.";
                  };
                };
              }
            );
            default = [ ];
            description = "Custom provision scripts for the virtual machine.";
          };
          sshConfig = mkOption {
            type = types.bool;
            default = true;
            description = "Modify ~/.ssh/config automatically.";
          };
          sshPort = mkOption {
            type = types.int;
            default = 0;
            description = "The port number for the SSH server.";
          };
          mounts = mkOption {
            type = types.listOf (
              types.submodule {
                options = {
                  location = mkOption {
                    type = types.str;
                    description = "Location to mount.";
                  };
                  writable = mkOption {
                    type = types.bool;
                    default = true;
                    description = "Whether the mount is writable.";
                  };
                };
              }
            );
            default = [ ];
            description = "Configure volume mounts for the virtual machine.";
          };
          diskImage = mkOption {
            type = types.str;
            default = "";
            description = "Specify a custom disk image.";
          };
          env = mkOption {
            type = types.attrsOf types.str;
            default = { };
            description = "Environment variables for the virtual machine.";
          };
        };
      };
      default = { };
      description = "Colima configuration settings.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".colima/default/colima.yaml" = {
      source = yamlFormat.generate "colima.yaml" cfg.settings;
    };

    # Set dynamic default for mountType based on vmType (Darwin/Linux-safe)
    services.colima.settings.mountType = mkDefault (
      if pkgs.stdenv.isDarwin && cfg.settings.vmType == "vz" then
        "virtiofs"
      else if cfg.settings.vmType == "qemu" then
        "9p"
      else
        "sshfs"
    );

    programs.docker-cli.contexts = mkIf cfg.addDockerContext {
      colima = {
        Metadata = {
          Description = "Colima container runtime";
        };
        Endpoints.docker.Host = "unix://${config.home.homeDirectory}/.colima/default/docker.sock";
      };
    };

    programs.docker-cli.settings.currentContext = mkIf cfg.useAsDefaultContext "colima";

    # Darwin configuration
    launchd.agents.colima = mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "${cfg.package}/bin/colima"
          "start"
          "-f"
          "--save-config=false"
        ];
        KeepAlive = true;
        RunAtLoad = true;
        EnvironmentVariables.PATH = "${cfg.package}/bin:${pkgs.perl}/bin:${pkgs.docker}/bin:/usr/bin:/usr/sbin:/sbin";
        StandardOutPath = cfg.logFile;
        StandardErrorPath = cfg.logFile;
      };
    };

    # Linux configuration
    systemd.user.services.colima = mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Colima container runtime";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${cfg.package}/bin/colima start -f --save-config=false";
        Restart = "always";
        RestartSec = 2;
        Environment = [
          "PATH=${cfg.package}/bin:${pkgs.perl}/bin:${pkgs.docker}/bin:/usr/bin:/usr/sbin:/sbin"
        ];
        StandardOutput = "append:${cfg.logFile}";
        StandardError = "append:${cfg.logFile}";
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
    };
  };
}
