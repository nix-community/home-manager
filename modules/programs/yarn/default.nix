{
  lib,
  pkgs,
  config,
  ...
}:
let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    ;

  cfg = config.programs.yarn;

  yamlFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.maintainers.friedrichaltheide ];

  options.programs.yarn = {
    enable = mkEnableOption "management of yarn config";

    settings = mkOption {
      type = yamlFormat.type;
      default = { };
      example = ''
        {
          httpProxy = "http://proxy.example.org:3128";
          httpsProxy = "http://proxy.example.org:3128";
        }
      '';
      description = ''
        Available configuration options for yarn see:
        <https://yarnpkg.com/configuration/yarnrc>
      '';
    };
  };

  config = mkIf cfg.enable {
    home = {
      file =
        let
          yarnRcFileName = ".yarnrc.yml";
        in
        {
          "${yarnRcFileName}" = {
            source = yamlFormat.generate "${yarnRcFileName}" cfg.settings;
          };
        };
    };
  };
}
