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

    profiles = lib.mkOption {
      default = {
        default = {
          isActive = true;
          isService = true;
        };
      };
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

              logFile = lib.mkOption {
                type = lib.types.path;
                default = "${config.home.homeDirectory}/.local/state/colima-${name}.log";
                defaultText = lib.literalExpression "\${config.home.homeDirectory}/.local/state/colima-\${name}.log";
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

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = (lib.count (p: p.isActive) (lib.attrValues cfg.profiles)) <= 1;
        message = "Only one Colima profile can be active at a time.";
      }
    ];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file = lib.mkMerge (
      lib.mapAttrsToList (profileName: profile: {
        ".colima/${profileName}/colima.yaml" = {
          source = yamlFormat.generate "colima.yaml" profile.settings;
        };
      }) (lib.filterAttrs (name: profile: profile.settings != { }) cfg.profiles)
    );

    programs.docker-cli.settings.currentContext =
      let
        activeProfile = lib.findFirst (p: p.isActive) null (lib.attrValues cfg.profiles);
      in
      lib.mkIf (activeProfile != null) (
        if activeProfile.name != "default" then "colima-${activeProfile.name}" else "colima"
      );

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
          EnvironmentVariables.PATH = lib.makeBinPath [
            cfg.package
            cfg.perlPackage
            cfg.dockerPackage
            cfg.sshPackage
            cfg.coreutilsPackage
            cfg.curlPackage
            cfg.bashPackage
            pkgs.darwin.DarwinTools
          ];
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
            "PATH=${
              lib.makeBinPath [
                cfg.package
                cfg.perlPackage
                cfg.dockerPackage
                cfg.sshPackage
                cfg.coreutilsPackage
                cfg.curlPackage
                cfg.bashPackage
              ]
            }"
          ];
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
