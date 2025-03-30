{ config, lib, pkgs, ... }:
let
  cfg = config.programs.alacritty;
  tomlFormat = pkgs.formats.toml { };
in {
  options = {
    programs.alacritty = {
      enable = lib.mkEnableOption "Alacritty";

      package = lib.mkPackageOption pkgs "alacritty" { nullable = true; };

      theme = lib.mkOption {
        type = with lib.types; nullOr str;
        default = null;
        example = "solarized_dark";
        description = ''
          A theme from the
          [alacritty-theme](https://github.com/alacritty/alacritty-theme)
          repository to import in the configuration.
          See <https://github.com/alacritty/alacritty-theme/tree/master/themes>
          for a list of available themes.
          If you would like to import your own theme, use
          {option}`programs.alacritty.settings.general.import` or
          {option}`programs.alacritty.settings.colors` directly.
        '';
      };

      settings = lib.mkOption {
        type = tomlFormat.type;
        default = { };
        example = lib.literalExpression ''
          {
            window.dimensions = {
              lines = 3;
              columns = 200;
            };
            keyboard.bindings = [
              {
                key = "K";
                mods = "Control";
                chars = "\\u000c";
              }
            ];
          }
        '';
        description = ''
          Configuration written to
          {file}`$XDG_CONFIG_HOME/alacritty/alacritty.yml` or
          {file}`$XDG_CONFIG_HOME/alacritty/alacritty.toml`
          (the latter being used for alacritty 0.13 and later).
          See <https://github.com/alacritty/alacritty/tree/master#configuration>
          for more info.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [{
      # If using the theme option, ensure that theme exists in the
      # alacritty-theme package.
      assertion = let
        available = lib.pipe "${pkgs.alacritty-theme}/share/alacritty-theme" [
          builtins.readDir
          (lib.filterAttrs
            (name: type: type == "regular" && lib.hasSuffix ".toml" name))
          lib.attrNames
          (lib.map (lib.removeSuffix ".toml"))
        ];
      in cfg.theme == null || (builtins.elem cfg.theme available);
      message = "The alacritty theme '${cfg.theme}' does not exist.";
    }];

    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    programs.alacritty.settings = let
      theme = "${pkgs.alacritty-theme}/share/alacritty-theme/${cfg.theme}.toml";
    in lib.mkIf (cfg.theme != null) {
      general.import =
        lib.mkIf (lib.versionAtLeast cfg.package.version "0.14") [ theme ];
      import = lib.mkIf (lib.versionOlder cfg.package.version "0.14") [ theme ];
    };

    xdg.configFile."alacritty/alacritty.toml" = lib.mkIf (cfg.settings != { }) {
      source = (tomlFormat.generate "alacritty.toml" cfg.settings).overrideAttrs
        (finalAttrs: prevAttrs: {
          buildCommand = lib.concatStringsSep "\n" [
            prevAttrs.buildCommand
            # TODO: why is this needed? Is there a better way to retain escape sequences?
            "substituteInPlace $out --replace-quiet '\\\\' '\\'"
          ];
        });
    };
  };
}
