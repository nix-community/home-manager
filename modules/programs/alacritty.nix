{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.alacritty;
  useToml = lib.versionAtLeast cfg.package.version "0.13";
  tomlFormat = pkgs.formats.toml { };
  configFileName = "alacritty.${if useToml then "toml" else "yml"}";
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
                chars = "\\x0c";
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

    xdg.configFile."alacritty/${configFileName}" =
      lib.mkIf (cfg.settings != { }) (lib.mkMerge [
        (lib.mkIf useToml {
          source =
            (tomlFormat.generate configFileName cfg.settings).overrideAttrs
            (finalAttrs: prevAttrs: {
              buildCommand = lib.concatStringsSep "\n" [
                prevAttrs.buildCommand
                # TODO: why is this needed? Is there a better way to retain escape sequences?
                "substituteInPlace $out --replace '\\\\' '\\'"
              ];
            });
        })
        # TODO remove this once we don't need to support Alacritty < 0.12 anymore
        (lib.mkIf (!useToml) {
          text =
            replaceStrings [ "\\\\" ] [ "\\" ] (builtins.toJSON cfg.settings);
        })
      ]);
  };
}
