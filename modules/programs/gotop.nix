{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.gotop;
  inherit (pkgs.stdenv.hostPlatform) isDarwin;
in {
  meta.maintainers = [ maintainers.geowy ];

  options.programs.gotop = {
    enable =
      mkEnableOption "gotop, a terminal based graphical activity monitor";

    settings = mkOption {
      type = types.attrsOf types.str;
      default = { };
      defaultText = literalExample "{ }";
      example = literalExample ''
        {
          colorscheme = "solarized";
          layout = "kitchensink";
        }
      '';
      description = ''
        gotop configuration options. Available options are described
        in the gotop documentation:
        <link xlink:href="https://github.com/xxxserxxx/gotop/blob/master/docs/configuration.md"/>.
      '';
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      home.packages = [ pkgs.gotop ];

      home.file."Library/Application Support/gotop/gotop.conf" =
        mkIf (cfg.settings != { } && isDarwin) {
          text = generators.toKeyValue { } cfg.settings;
        };

      xdg.configFile."gotop/gotop.conf" =
        mkIf (cfg.settings != { } && !isDarwin) {
          text = generators.toKeyValue { } cfg.settings;
        };
    })
  ];
}
