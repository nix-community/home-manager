{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.skhd;
in
{
  meta.maintainers = [ lib.maintainers.khaneliman ];

  options.services.skhd = {
    enable = lib.mkEnableOption "skhd";

    package = lib.mkPackageOption pkgs "skhd" { };

    errorLogFile = lib.mkOption {
      type = with lib.types; nullOr (either path str);
      defaultText = lib.literalExpression "\${config.home.homeDirectory}/Library/Logs/skhd/err.log";
      example = "/Users/khaneliman/Library/Logs/skhd.log";
      description = "Absolute path to log all stderr output.";
    };

    outLogFile = lib.mkOption {
      type = with lib.types; nullOr (either path str);
      defaultText = lib.literalExpression "\${config.home.homeDirectory}/Library/Logs/skhd/out.log";
      example = "/Users/khaneliman/Library/Logs/skhd.log";
      description = "Absolute path to log all stdout output.";
    };

    config = lib.mkOption {
      type = with lib.types; nullOr (either path lines);
      default = null;
      example = ''
        # open terminal, blazingly fast compared to iTerm/Hyper
        cmd - return : /Applications/kitty.app/Contents/MacOS/kitty --single-instance -d ~

        # open qutebrowser
        cmd + shift - return : ~/Scripts/qtb.sh

        # open mpv
        cmd - m : open -na /Applications/mpv.app $(pbpaste)
      '';
      description = ''
        Contents of skhd's configuration file. If empty (the default), the configuration file won't be managed.

        See [documentation](https://github.com/koekeishiya/skhd)
        and [example](https://github.com/koekeishiya/skhd/blob/master/examples/skhdrc).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.skhd" pkgs lib.platforms.darwin)
    ];

    home.packages = [ cfg.package ];

    launchd.agents.skhd = {
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

    services.skhd = {
      errorLogFile = lib.mkOptionDefault "${config.home.homeDirectory}/Library/Logs/skhd/skhd.err.log";
      outLogFile = lib.mkOptionDefault "${config.home.homeDirectory}/Library/Logs/skhd/skhd.out.log";
    };

    xdg.configFile."skhd/skhdrc" = lib.mkIf (cfg.config != null) {
      source =
        if builtins.isPath cfg.config || lib.isStorePath cfg.config then
          cfg.config
        else
          pkgs.writeScript "skhdrc" cfg.config;
    };
  };
}
