{
  config,
  lib,
  pkgs,
  ...
}:
let

  cfg = config.programs.mistral-vibe;

  settingsFormat = pkgs.formats.toml { };

in
{
  meta.maintainers = with lib.maintainers; [
    GaetanLepage
    mana-byte
  ];

  options.programs.mistral-vibe = {
    enable = lib.mkEnableOption "Mistral Vibe, Mistral's open-source CLI coding assistant";

    package = lib.mkPackageOption pkgs "mistral-vibe" { nullable = true; };

    settings = lib.mkOption {
      type = settingsFormat.type;
      default = { };
      example = lib.literalExpression ''
        {
          active_model = "devstral-latest";
          vim_keybindings = false;
          tool_paths = [];

          providers = [
            {
              name = "mistral";
              backend = "mistral";
              api_base = "https://api.mistral.ai/v1";
              api_key_env_var = "MISTRAL_API_KEY";
              api_style = "openai";
            }
          ];

          models = [
            {
              name = "devstral-latest";
              provider = "mistral";
              alias = "devstral-latest";
              temperature = 0.1;
              input_price = 0.4;
              output_price = 2.0;
            }
          ];
        }
      '';
      description = ''
        Mistral Vibe configuration.
        For available settings see <https://github.com/mistralai/mistral-vibe>.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    home.file.".vibe/config.toml".source = settingsFormat.generate "config.toml" cfg.settings;
  };
}
