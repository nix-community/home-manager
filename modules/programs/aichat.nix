{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.aichat;

  settingsFormat = pkgs.formats.yaml { };

  inherit (pkgs.stdenv.hostPlatform) isLinux isDarwin;
in
{
  meta.maintainers = [
    lib.maintainers.jaredmontoya
  ];

  options.programs.aichat = {
    enable = lib.mkEnableOption "aichat, an All-in-one LLM CLI tool";

    package = lib.mkPackageOption pkgs "aichat" { nullable = true; };

    settings = lib.mkOption {
      inherit (settingsFormat) type;
      default = { };
      defaultText = lib.literalExpression "{ }";
      example = lib.literalExpression ''
        {
          model = "ollama:mistral-small3.1:latest";
          clients = [
            {
              type = "openai-compatible";
              name = "ollama";
              api_base = "http://localhost:11434/v1";
              models = [
                {
                  name = "mistral-small3.1:latest";
                  supports_function_calling = true;
                  supports_vision = true;
                }
              ];
            }
          ];
        }
      '';
      description = ''
        Configuration written to
        {file}`$XDG_CONFIG_HOME/aichat/config.yaml`
        on Linux or on Darwin if [](#opt-xdg.enable) is set, otherwise
        {file}`~/Library/Application Support/aichat/config.yaml`.
        See
        <https://github.com/sigoden/aichat/blob/main/config.example.yaml>
        for supported values.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file."Library/Application Support/aichat/config.yaml" =
      mkIf (cfg.settings != { } && (isDarwin && !config.xdg.enable))
        {
          source = settingsFormat.generate "aichat-config" cfg.settings;
        };

    xdg.configFile."aichat/config.yaml" = mkIf (cfg.settings != { } && (isLinux || config.xdg.enable)) {
      source = settingsFormat.generate "aichat-config" cfg.settings;
    };
  };
}
