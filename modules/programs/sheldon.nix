{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    hm
    mkEnableOption
    mkIf
    mkOption
    ;
  cfg = config.programs.sheldon;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with hm.maintainers; [
    Kyure-A
    mainrs
    elanora96
  ];

  options.programs.sheldon = {
    enable = mkEnableOption "sheldon";

    package = lib.mkPackageOption pkgs "sheldon" { };

    settings = mkOption {
      inherit (tomlFormat) type;
      default = { };
      description = "";
      example = lib.literalExpression "";
    };

    enableZshIntegration = hm.shell.mkZshIntegrationOption { inherit config; };

    enableBashIntegration = hm.shell.mkBashIntegrationOption { inherit config; };

    enableFishIntegration = hm.shell.mkFishIntegrationOption { inherit config; };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."sheldon/plugins.toml" = mkIf (cfg.settings != { }) {
      source = tomlFormat.generate "sheldon-config" cfg.settings;
    };

    programs.bash.initExtra = mkIf cfg.enableBashIntegration ''
      eval "$(sheldon source)"
    '';

    programs.zsh.initContent = mkIf cfg.enableZshIntegration ''
      eval "$(sheldon source)"
    '';

    programs.fish.interactiveShellInit = mkIf cfg.enableFishIntegration ''
      eval "$(sheldon source)"
    '';
  };
}
