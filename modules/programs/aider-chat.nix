{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.aider-chat;
  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];
  options.programs.aider-chat = {
    enable = mkEnableOption "aider-chat";
    package = mkPackageOption pkgs "aider-chat" { nullable = true; };
    settings = mkOption {
      inherit (yamlFormat) type;
      default = { };
      example = {
        verify-ssl = false;
        architect = true;
        auto-accept-architect = false;
        show-model-warnings = false;
        check-model-accepts-settings = false;
        cache-prompts = true;
        dark-mode = true;
        dirty-commits = false;
        lint = true;
      };
      description = ''
        Configuration settings for aider-chat. All the available options can be found here:
        <https://aider.chat/docs/config/aider_conf.html#sample-yaml-config-file>.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    home.file.".aider.conf.yml" = mkIf (cfg.settings != { }) {
      source = yamlFormat.generate "aider.conf.yml" cfg.settings;
    };
  };
}
