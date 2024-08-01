{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.alacritty;
  tomlFormat = pkgs.formats.toml { };
in {
  options = {
    programs.alacritty = {
      enable = mkEnableOption "Alacritty";

      package = mkOption {
        type = types.package;
        default = pkgs.alacritty;
        defaultText = literalExpression "pkgs.alacritty";
        description = "The Alacritty package to install.";
      };

      theme = mkOption {
        type = let
          themes = with lib;
            pipe pkgs.alacritty-theme [
              builtins.readDir
              (filterAttrs
                (name: type: type == "regular" && hasSuffix ".toml" name))
              attrNames
              (map (removeSuffix ".toml"))
            ];
        in with types;
        nullOr (enum themes) // {
          description = ''
            a theme present in [`alacritty-theme`], i.e. its filename without extension
            [`alacritty-theme`]: https://github.com/alacritty/alacritty-theme/tree/${pkgs.alacritty-theme.src.rev}/themes
          '';
        };
        default = null;
        example = "solarized_dark";
        description = ''
          A theme to import in the configuration, taken from the [`alacritty-theme`] repository,
          as [packaged] in `nixpkgs`.
          [`alacritty-theme`]: https://github.com/alacritty/alacritty-theme
          [packaged]: https://search.nixos.org/packages?query=alacritty-theme
        '';
      };

      settings = mkOption {
        type = tomlFormat.type;
        default = { };
        example = literalExpression ''
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

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    programs.alacritty.settings.import =
      mkIf (cfg.theme != null) [ "${pkgs.alacritty-theme}/${cfg.theme}.toml" ];

    xdg.configFile."alacritty/alacritty.toml" = lib.mkIf (cfg.settings != { }) {
      source = (tomlFormat.generate "alacritty.toml" cfg.settings).overrideAttrs
        (finalAttrs: prevAttrs: {
          buildCommand = lib.concatStringsSep "\n" [
            prevAttrs.buildCommand
            # TODO: why is this needed? Is there a better way to retain escape sequences?
            "substituteInPlace $out --replace '\\\\' '\\'"
          ];
        });
    };
  };
}
