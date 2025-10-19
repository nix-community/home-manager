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
    dockerPackage = lib.mkPackageOption pkgs "docker" { };
    perlPackage = lib.mkPackageOption pkgs "perl" { };

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

    settings = lib.mkOption {
      type = lib.yamlFormat.type;
      default = { };
      description = "Colima configuration settings, see <https://github.com/abiosoft/colima/blob/main/embedded/defaults/colima.yaml> or run `colima template`.";
      example = lib.literalExpression ''
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

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    home.file.".colima/default/colima.yaml" = {
      source = yamlFormat.generate "colima.yaml" cfg.settings;
    };

    programs.docker-cli.contexts = mkIf cfg.addDockerContext {
      colima = {
        Metadata = {
          Description = "Colima container runtime";
        };
        Endpoints.docker.Host = "unix://${config.home.homeDirectory}/.colima/default/docker.sock";
      };
    };

    programs.docker-cli.settings.currentContext = mkIf cfg.useAsDefaultContext "colima";

    launchd.agents.colima = mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [
          "${lib.getExe cfg.package}"
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

    systemd.user.services.colima = mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Colima container runtime";
        After = [ "network-online.target" ];
        Wants = [ "network-online.target" ];
      };
      Service = {
        ExecStart = "${lib.getExe cfg.package} start -f --save-config=false";
        Restart = "always";
        RestartSec = 2;
        Environment = [
          "PATH=${cfg.package}/bin:${cfg.perlPackage}/bin:${cfg.dockerPackage}/bin:/usr/bin:/usr/sbin:/sbin"
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
