{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.open-webui;
  webuiHome = "${config.xdg.dataHome}/open-webui";
  webuiLogDir = "${webuiHome}/logs";
  command = [
    (lib.getExe cfg.package)
    "serve"
    "--host"
    cfg.host
    "--port"
    (toString cfg.port)
  ];
  environmentVariables = {
    DATA_DIR = "${webuiHome}/data";
    STATIC_DIR = "${webuiHome}/static";
    HF_HOME = "${webuiHome}/hf_home";
    SENTENCE_TRANSFORMERS_HOME = "${webuiHome}/transformers_home";
  }
  // lib.optionalAttrs (cfg.openai.baseUrls != [ ]) {
    OPENAI_API_BASE_URLS = lib.concatStringsSep ";" cfg.openai.baseUrls;
  }
  // lib.optionalAttrs (cfg.webuiUrl != null) {
    WEBUI_URL = cfg.webuiUrl;
  }
  // cfg.environment;
in
{
  meta.maintainers = [ lib.maintainers.gordon01 ];

  options.services.open-webui = {
    enable = lib.mkEnableOption "Open WebUI: Self-Hosted AI Platform";

    package = lib.mkPackageOption pkgs "open-webui" { };

    environment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        ENABLE_OLLAMA_API = "False";
      };
      description = ''
        Additional environment variables for the Open WebUI service.
        These override module-provided values.

        See <https://docs.openwebui.com/reference/env-configuration/>.
      '';
    };

    webuiUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "https://chat.example.com";
      description = ''
        Specifies the URL where your Open WebUI installation is reachable.
        Needed for search engine support and OAuth/SSO.
      '';
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address on which the Open WebUI server listens.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Port on which the Open WebUI server listens.";
    };

    openai.baseUrls = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "http://localhost:8080/v1" ];
      description = ''
        Base URLs of OpenAI-compatible API servers, including any required
        path prefix such as /v1.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.dataFile."open-webui/home/.keep".text = "";

    systemd.user.services.open-webui = lib.mkIf pkgs.stdenv.hostPlatform.isLinux {
      Unit = {
        Description = "Open WebUI";
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        ExecStart = lib.concatStringsSep " " command;
        Environment = lib.mapAttrsToList (name: value: "${name}=${value}") environmentVariables;
        WorkingDirectory = "${webuiHome}/home";
      };
    };

    launchd.agents.open-webui = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
      enable = true;
      config = {
        ProgramArguments = command;
        EnvironmentVariables = environmentVariables;
        RunAtLoad = true;
        KeepAlive = true;
        WorkingDirectory = "${webuiHome}/home";
        StandardOutPath = "${webuiLogDir}/output.log";
        StandardErrorPath = "${webuiLogDir}/error.log";
      };
    };
  };
}
