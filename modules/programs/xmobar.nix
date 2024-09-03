{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  cfg = config.programs.xmobar;
  convertDate =
    _commands:
    "Run Date "
    + _commands.date
    + " \"date\""
    + " 10"
    + "\n"
    + "Run Com "
    + "\""
    + _commands.com.executable
    + "\"";
in
{
  options.programs.xmobar = {
    enable = mkEnableOption "Xmobar, a minimalistic status bar";

    package = mkOption {
      default = pkgs.haskellPackages.xmobar;
      defaultText = literalExpression "pkgs.haskellPackages.xmobar";
      type = types.package;
      description = ''
        Package providing the {command}`xmobar` binary.
      '';
    };

    extraConfig = mkOption {
      default = "";
      example = literalExpression ''
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
      type = types.lines;
      description = ''
        Extra configuration lines to add to
        {file}`$XDG_CONFIG_HOME/xmobar/.xmobarrc`.
        See
        <https://xmobar.org/#configuration>
        for options.
      '';
    };

    commands = mkOption {
      type = types.submodule {
        options = {
          date = mkOption {
            type = types.str;
            description = "Date monitor";
          };
          com = mkOption {
            type = types.submodule {
              options = {
                executable = mkOption {
                  type = types.str;
                  description = "Executable name";
                };
                arguments = mkOption {
                  type = types.listOf types.str;
                  description = "Command line arguments to pass to the executable.";
                };
                rate = mkOption {
                  type = types.int;
                  description = "Refresh rate in tenth of s second.";
                };
              };
            };
            description = "Executing external commands";
          };
        };
      };
      description = "All the possible commands of Xmobar";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];
    xdg.configFile."xmobar/.xmobarrc".text = cfg.extraConfig;
    xdg.configFile."xmobar/bla.txt".text = convertDate cfg.commands;
  };

  meta.maintainers = [ hm.maintainers.t4ccer ];
}
