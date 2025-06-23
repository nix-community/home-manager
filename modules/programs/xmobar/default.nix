{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.xmobar;
in
{
  options.programs.xmobar = {
    enable = lib.mkEnableOption "Xmobar, a minimalistic status bar";

    package = lib.mkPackageOption pkgs [ "haskellPackages" "xmobar" ] { };

    extraConfig = lib.mkOption {
      default = "";
      example = lib.literalExpression ''
        Config
          { font        = "Fira Code"
          , borderColor = "#d0d0d0"
          , border      = FullB
          , borderWidth = 3
          , bgColor     = "#222"
          , fgColor     = "grey"
          , position    = TopSize C 99 30
          , commands    =
              [ Run Cpu ["-t", "cpu: <fc=#4eb4fa><bar> <total>%</fc>"] 10
              , Run Network "enp3s0" ["-S", "True", "-t", "eth: <fc=#4eb4fa><rx></fc>/<fc=#4eb4fa><tx></fc>"] 10
              , Run Memory ["-t","mem: <fc=#4eb4fa><usedbar> <usedratio>%</fc>"] 10
              , Run Date "date: <fc=#4eb4fa>%a %d %b %Y %H:%M:%S </fc>" "date" 10
              , Run StdinReader
              ]
          , sepChar     = "%"
          , alignSep    = "}{"
          , template    = "  %StdinReader% | %cpu% | %memory% | %enp3s0%  }{%date%  "
          }
      '';
      type = lib.types.lines;
      description = ''
        Extra configuration lines to add to
        {file}`$XDG_CONFIG_HOME/xmobar/.xmobarrc`.
        See
        <https://xmobar.org/#configuration>
        for options.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."xmobar/.xmobarrc".text = cfg.extraConfig;
  };

  meta.maintainers = [ lib.hm.maintainers.t4ccer ];
}
