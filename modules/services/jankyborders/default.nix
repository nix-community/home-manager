{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.jankyborders;
in
{
  meta.maintainers = [ lib.maintainers.khaneliman ];

  options.services.jankyborders = {
    enable = lib.mkEnableOption "jankyborders";

    package = lib.mkPackageOption pkgs "jankyborders" { };

    errorLogFile = lib.mkOption {
      type = with lib.types; nullOr (either path str);
      defaultText = lib.literalExpression "\${config.home.homeDirectory}/Library/Logs/jankyborders/err.log";
      example = "/Users/khaneliman/Library/Logs/jankyborders.log";
      description = "Absolute path to log all stderr output.";
    };

    outLogFile = lib.mkOption {
      type = with lib.types; nullOr (either path str);
      defaultText = lib.literalExpression "\${config.home.homeDirectory}/Library/Logs/jankyborders/out.log";
      example = "/Users/khaneliman/Library/Logs/jankyborders.log";
      description = "Absolute path to log all stdout output.";
    };

    settings = lib.mkOption {
      type = with lib.types; attrsOf anything;
      default = { };
      example = lib.literalExpression ''
                {
                  style=round;
        	        width=6.0;
        	        hidpi="off";
        	        active_color="0xffe2e2e3";
        	        inactive_color="0xff414550";
                }
      '';
      description = ''
        Configuration settings to passed to `borders` in
        {file}`$XDG_CONFIG_HOME/borders/bordersc`. See
        <https://github.com/FelixKratz/JankyBorders>
        for the documentation.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.jankyborders" pkgs lib.platforms.darwin)
    ];

    home.packages = [ cfg.package ];

    launchd.agents.jankyborders = {
      enable = true;
      config = {
        ProgramArguments = [ (lib.getExe cfg.package) ];
        ProcessType = "Interactive";
        KeepAlive = true;
        RunAtLoad = true;
        StandardErrorPath = cfg.errorLogFile;
        StandardOutPath = cfg.outLogFile;
      };
    };

    services.jankyborders = {
      errorLogFile = lib.mkOptionDefault "${config.home.homeDirectory}/Library/Logs/borders/borders.err.log";
      outLogFile = lib.mkOptionDefault "${config.home.homeDirectory}/Library/Logs/borders/borders.out.log";
    };

    xdg.configFile."borders/bordersrc".source = pkgs.writeShellScript "bordersrc" ''
      options=(
      ${lib.generators.toKeyValue { indent = "  "; } cfg.settings})

      ${lib.getExe cfg.package} "''${options[@]}"
    '';
  };
}
