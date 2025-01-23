{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.ollama;

  ollamaPackage = if cfg.acceleration == null then
    cfg.package
  else
    cfg.package.override { inherit (cfg) acceleration; };

in {
  meta.maintainers = [ maintainers.terlar ];

  options = {
    services.ollama = {
      enable = mkEnableOption "ollama server for local large language models";

      package = mkPackageOption pkgs "ollama" { };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "[::]";
        description = ''
          The host address which the ollama server HTTP interface listens to.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 11434;
        example = 11111;
        description = ''
          Which port the ollama server listens to.
        '';
      };

      acceleration = mkOption {
        type = types.nullOr (types.enum [ false "rocm" "cuda" ]);
        default = null;
        example = "rocm";
        description = ''
          What interface to use for hardware acceleration.

          - `null`: default behavior
            - if `nixpkgs.config.rocmSupport` is enabled, uses `"rocm"`
            - if `nixpkgs.config.cudaSupport` is enabled, uses `"cuda"`
            - otherwise defaults to `false`
          - `false`: disable GPU, only use CPU
          - `"rocm"`: supported by most modern AMD GPUs
            - may require overriding gpu type with `services.ollama.rocmOverrideGfx`
              if rocm doesn't detect your AMD gpu
          - `"cuda"`: supported by most modern NVIDIA GPUs
        '';
      };

      environmentVariables = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          OLLAMA_LLM_LIBRARY = "cpu";
          HIP_VISIBLE_DEVICES = "0,1";
        };
        description = ''
          Set arbitrary environment variables for the ollama service.

          Be aware that these are only seen by the ollama server (systemd service),
          not normal invocations like `ollama run`.
          Since `ollama run` is mostly a shell around the ollama server, this is usually sufficient.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.user.services.ollama = mkIf pkgs.stdenv.isLinux {
      Unit = {
        Description = "Server for local large language models";
        After = [ "network.target" ];
      };

      Service = {
        ExecStart = "${getExe ollamaPackage} serve";
        Environment =
          (mapAttrsToList (n: v: "${n}=${v}") cfg.environmentVariables)
          ++ [ "OLLAMA_HOST=${cfg.host}:${toString cfg.port}" ];
      };

      Install = { WantedBy = [ "default.target" ]; };
    };

    launchd.agents.ollama = mkIf pkgs.stdenv.isDarwin {
      enable = true;
      config = {
        ProgramArguments = [ "${getExe ollamaPackage}" "serve" ];
        EnvironmentVariables = cfg.environmentVariables // {
          OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
        };
        KeepAlive = {
          Crashed = true;
          SuccessfulExit = false;
        };
        ProcessType = "Background";
      };
    };

    home.packages = [ ollamaPackage ];
  };
}
