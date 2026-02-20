{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.colima;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [
    lib.hm.maintainers.will-lol
  ];

  options.services.colima = {
    enable = lib.mkEnableOption "Colima, a container runtime";

    colimaHomeDir = lib.mkOption {
      type = lib.types.str;
      apply = p: lib.removePrefix "${config.home.homeDirectory}/" p;
      default =
        if config.xdg.enable && lib.versionAtLeast config.home.stateVersion "26.05" then
          "${config.xdg.configHome}/colima"
        else
          ".colima";
      defaultText = lib.literalExpression ''
        if config.xdg.enable && lib.versionAtLeast config.home.stateVersion "26.05" then
          "$XDG_CONFIG_HOME/colima"
        else
          ".colima"
      '';
      example = lib.literalExpression "\${config.xdg.configHome}/colima";
      description = "Directory to store colima configuration. This also sets $COLIMA_HOME.";
    };

    limaHomeDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      apply = p: if p != null then lib.removePrefix "${config.home.homeDirectory}/" p else p;
      default = null;
      defaultText = "Colima uses $COLIMA_HOME/_lima by default.";
      example = lib.literalExpression "\${config.xdg.dataHome}/lima";
      description = "Directory to store lima files. This also sets $LIMA_HOME.";
    };

    package = lib.mkPackageOption pkgs "colima" { };
    dockerPackage = lib.mkPackageOption pkgs "docker" {
      extraDescription = "Used by colima to activate profiles. Not needed if no profile is set to isActive.";
    };
    perlPackage = lib.mkPackageOption pkgs "perl" {
      extraDescription = "Used by colima during image download for the shasum command.";
    };
    sshPackage = lib.mkPackageOption pkgs "openssh" {
      extraDescription = "Used by colima to manage the vm.";
    };
    coreutilsPackage = lib.mkPackageOption pkgs "coreutils" {
      extraDescription = "Used in various ways by colima.";
    };
    curlPackage = lib.mkPackageOption pkgs "curl" {
      extraDescription = "Used by colima to donwload images.";
    };
    bashPackage = lib.mkPackageOption pkgs "bashNonInteractive" {
      extraDescription = "Used by colima's internal scripts.";
    };
    kubectlPackage = lib.mkPackageOption pkgs "kubectl" {
      extraDescription = "Used by colima when kubernetes is enabled in the profile.";
    };

    profiles = lib.mkOption {
      default = {
        default = {
          isActive = true;
          isService = true;
          setDockerHost = lib.versionAtLeast config.home.stateVersion "26.05";
        };
      };
      defaultText = lib.literalExpression ''
        {
          default = {
            isActive = true;
            isService = true;
            setDockerHost = lib.versionAtLeast config.home.stateVersion "26.05";
          };
        };
      '';
      description = ''
        Profiles allow multiple colima configurations. The default profile is active by default.
        If you have used colima before, you may need to delete existing configuration using `colima delete` or use a different profile.

        Note that removing a configured profile will not delete the corresponding Colima instance.
        You will need to manually run `colima delete <profile-name>` to remove the instance and release resources.
      '';
      example = ''
        {
          default = {
            isActive = true;
            isService = true;
            setDockerHost = true;
          };
          rosetta = {
            isService = true;
            settings.rosetta = true;
          };
          powerful = {
            settings.cpu = 8;
          };
        };
      '';
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                default = name;
                readOnly = true;
                description = "The profile's name.";
              };

              isService = lib.mkOption {
                type = lib.types.bool;
                default = false;
                example = true;
                description = ''
                  Whether this profile will run as a service.
                '';
              };

              isActive = lib.mkOption {
                type = lib.types.bool;
                default = false;
                example = true;
                description = ''
                  Whether to set this profile as:
                  - active docker context
                  - active kubernetes context
                  - active incus remote
                  Exactly one or zero profiles should have this option set.
                '';
              };

              setDockerHost = lib.mkOption {
                type = lib.types.bool;
                default = false;
                example = true;
                description = ''
                  Set this context as $DOCKER_HOST.
                  Exactly one or zero profiles should have this option set.
                '';
              };

              logFile = lib.mkOption {
                type = lib.types.path;
                default = "${config.xdg.stateHome}/colima/${name}.log";
                defaultText = lib.literalExpression "\${config.xdg.stateHome}/colima/\${name}.log";
                description = "Combined stdout and stderr log file for the Colima service.";
              };

              settings = lib.mkOption {
                inherit (yamlFormat) type;
                default = { };
                description = "Colima configuration settings, see <https://github.com/abiosoft/colima/blob/main/embedded/defaults/colima.yaml> or run `colima template`.";
                example = ''
                  {
                    cpu = 2;
                    disk = 100;
                    memory = 2;
                    arch = "host";
                    runtime = "docker";
                    hostname = null;
                    kubernetes = {
                      enabled = false;
                      version = "v1.33.3+k3s1";
                      k3sArgs = [ "--disable=traefik" ];
                      port = 0;
                    };
                    autoActivate = true;
                    network = {
                      address = false;
                      mode = "shared";
                      interface = "en0";
                      preferredRoute = false;
                      dns = [ ];
                      dnsHosts = {
                        "host.docker.internal" = "host.lima.internal";
                      };
                      hostAddresses = false;
                    };
                    forwardAgent = false;
                    docker = { };
                    vmType = "qemu";
                    portForwarder = "ssh";
                    rosetta = false;
                    binfmt = true;
                    nestedVirtualization = false;
                    mountType = "sshfs";
                    mountInotify = false;
                    cpuType = "host";
                    provision = [ ];
                    sshConfig = true;
                    sshPort = 0;
                    mounts = [ ];
                    diskImage = "";
                    rootDisk = 20;
                    env = { };
                  }
                '';
              };
            };
          }
        )
      );
    };
  };

  config =
    let
      colimaHome = "${config.home.homeDirectory}/${cfg.colimaHomeDir}";
      limaHome =
        if cfg.limaHomeDir != null then "${config.home.homeDirectory}/${cfg.limaHomeDir}" else null;
      dockerConfig =
        if config.programs.docker-cli.enable then config.home.sessionVariables.DOCKER_CONFIG else null;
      activeProfile = lib.findFirst (p: p.isActive) null (lib.attrValues cfg.profiles);
      currentContext =
        if activeProfile != null then
          (if activeProfile.name == "default" then "colima" else "colima-${activeProfile.name}")
        else
          null;
      dockerHostProfile = lib.findFirst (p: p.setDockerHost) null (lib.attrValues cfg.profiles);
    in
    lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = (lib.count (p: p.isActive) (lib.attrValues cfg.profiles)) <= 1;
          message = "Only one Colima profile can be active at a time.";
        }
      ];

      home = {
        packages = lib.mkIf (cfg.package != null) [ cfg.package ];

        file = lib.mkMerge (
          lib.mapAttrsToList (profileName: profile: {
            "${cfg.colimaHomeDir}/${profileName}/colima.yaml" = {
              source = yamlFormat.generate "colima.yaml" profile.settings;
            };
          }) (lib.filterAttrs (name: profile: profile.settings != { }) cfg.profiles)
        );

        sessionVariables = {
          COLIMA_HOME = colimaHome;
        }
        // lib.optionalAttrs (limaHome != null) {
          LIMA_HOME = limaHome;
        }
        // lib.optionalAttrs (dockerHostProfile != null) {
          DOCKER_HOST = "unix://${colimaHome}/${dockerHostProfile.name}/docker.sock";
        };
      };

      programs.docker-cli.settings.currentContext = lib.mkIf (currentContext != null) currentContext;

      launchd.agents = lib.mapAttrs' (
        name: profile:
        lib.nameValuePair "colima-${name}" {
          enable = true;
          config = {
            ProgramArguments = [
              "${lib.getExe cfg.package}"
              "start"
              name
              "-f"
              "--activate=${if profile.isActive then "true" else "false"}"
              "--save-config=false"
            ];
            KeepAlive = {
              SuccessfulExit = true;
            };
            RunAtLoad = true;
            EnvironmentVariables = {
              COLIMA_HOME = colimaHome;
              PATH = lib.makeBinPath [
                cfg.package
                cfg.perlPackage
                cfg.dockerPackage
                cfg.sshPackage
                cfg.coreutilsPackage
                cfg.curlPackage
                cfg.bashPackage
                cfg.kubectlPackage
                pkgs.darwin.DarwinTools
              ];
            }
            // lib.optionalAttrs (limaHome != null) {
              LIMA_HOME = limaHome;
            }
            // lib.optionalAttrs (dockerConfig != null) {
              DOCKER_CONFIG = dockerConfig;
            }
            // lib.optionalAttrs config.xdg.enable {
              XDG_CACHE_HOME = config.xdg.cacheHome;
            };
            StandardOutPath = profile.logFile;
            StandardErrorPath = profile.logFile;
          };
        }
      ) (lib.filterAttrs (_: p: p.isService) cfg.profiles);

      systemd.user.services = lib.mapAttrs' (
        name: profile:
        lib.nameValuePair "colima-${name}" {
          Unit = {
            Description = "Colima container runtime (${name} profile)";
            After = [ "network-online.target" ];
            Wants = [ "network-online.target" ];
          };
          Service = {
            ExecStart = ''
              ${lib.getExe cfg.package} start ${name} \
                -f \
                --activate=${if profile.isActive then "true" else "false"} \
                --save-config=false
            '';
            Restart = "always";
            RestartSec = 2;
            Environment = [
              "COLIMA_HOME=${colimaHome}"
              "PATH=${
                lib.makeBinPath [
                  cfg.package
                  cfg.perlPackage
                  cfg.dockerPackage
                  cfg.sshPackage
                  cfg.coreutilsPackage
                  cfg.curlPackage
                  cfg.bashPackage
                  cfg.kubectlPackage
                ]
              }"
            ]
            ++ lib.optional (limaHome != null) "LIMA_HOME=${limaHome}"
            ++ lib.optional (dockerConfig != null) "DOCKER_CONFIG=${dockerConfig}";
            StandardOutput = "append:${profile.logFile}";
            StandardError = "append:${profile.logFile}";
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
        }
      ) (lib.filterAttrs (_: p: p.isService) cfg.profiles);
    };
}
