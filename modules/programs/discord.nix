{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.discord;
  jsonFormat = pkgs.formats.json { };
in
{
  meta.maintainers = with lib.hm.maintainers; [
    prescientmoon
  ];

  options.programs.discord = {
    enable = lib.mkEnableOption "Discord, the chat platform";
    package = lib.mkPackageOption pkgs "discord" { nullable = true; };
    settings = lib.mkOption {
      description = ''
        Configuration for Discord.
        The schema does not seem to be documented anywhere
      '';

      default = { };
      example = {
        DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
      };

      type = lib.types.submodule {
        freeformType = jsonFormat.type;
        options = {
          SKIP_HOST_UPDATE = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether to skip Discord's automatic update checks at startup
            '';

            # Discord refuses to launch if this is false and the nixpkgs version
            # is out of date
            default = true;
            example = false;
          };

          DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = lib.mkOption {
            type = lib.types.bool;
            description = ''
              Whether to enable Chrome's devtools inside Discord
            '';
            default = false;
            example = true;
          };
        };
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      configDir =
        if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else config.xdg.configHome;
    in
    {
      home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];
      home.file."${configDir}/discord/settings.json".source =
        jsonFormat.generate "discord-settings" cfg.settings;
    }
  );
}
