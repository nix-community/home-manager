{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    types
    mkIf
    mkEnableOption
    mkPackageOption
    mkOption
    ;

  cfg = config.programs.sketchybar;

  getSource = { name, arg }: if lib.isString arg then pkgs.writeText name arg else arg;

  getSketchybarrc =
    setting:
    if setting != "" then
      {
        "sketchybar/sketchybarrc".source = getSource {
          name = "sketchybarrc";
          arg = setting;
        };
      }
    else
      { };

  getPlugins =
    set:
    lib.mapAttrs' (
      name: value:
      lib.nameValuePair "sketchybar/plugins/${name}.sh" {
        source = getSource {
          name = "sketchybar-plugin-${name}";
          arg = value;
        };
      }
    ) set;
in
{
  meta.maintainers = with lib.hm.maintainers; [ aguirre-matteo ];

  options.programs.sketchybar = {
    enable = mkEnableOption "sketchybar";
    package = mkPackageOption pkgs "sketchybar" { nullable = true; };
    sketchybarrc = mkOption {
      type = with types; either lines path;
      default = "";
      example = ''
        PLUGIN_DIR="$CONFIG_DIR/plugins"

        sketchybar --bar position=top height=40 blur_radius=30 color=0x40000000
      '';
      description = ''
        Script to be written to the sketchybarrc. All the details about its contents
        can be found here: <https://felixkratz.github.io/SketchyBar/config/bar>.
      '';
    };
    plugins = mkOption {
      type = with types; attrsOf (either lines path);
      default = { };
      example = {
        window_title = ./plugins/window_title.sh;
        btc = ./plugins/btc.sh;
        eth = ./plugins/eth.sh;
      };
      description = ''
        Pluggins for SketchyBar. You can find some plugins at:
        <https://github.com/FelixKratz/SketchyBar/discussions/12>.
      '';
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.sketchybar" pkgs lib.platforms.darwin)
    ];

    home.packages = mkIf (cfg.package != null) [ cfg.package ];
    xdg.configFile = (getSketchybarrc cfg.sketchybarrc) // (getPlugins cfg.plugins);
  };
}
