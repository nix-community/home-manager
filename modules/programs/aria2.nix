{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.aria2;

  keyValueFormat = pkgs.formats.keyValue { };
in
{
  meta.maintainers = [ lib.maintainers.justinlovinger ];

  imports = [
    (lib.mkRemovedOptionModule [
      "programs"
      "aria2"
      "extraConfig"
    ] "This option has been removed. Please use 'programs.aria2.settings' instead.")
  ];

  options.programs.aria2 = {
    enable = lib.mkEnableOption "aria2";

    package = lib.mkPackageOption pkgs "aria2" { nullable = true; };

    settings = lib.mkOption {
      type = keyValueFormat.type;
      default = { };
      description = ''
        Options to add to {file}`aria2.conf` file.
        See
        {manpage}`aria2c(1)`
        for options.
      '';
      example = lib.literalExpression ''
        {
          listen-port = 60000;
          dht-listen-port = 60000;
          seed-ratio = 1.0;
          max-upload-limit = "50K";
          ftp-pasv = true;
        }
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."aria2/aria2.conf" = lib.mkIf (cfg.settings != { }) {
      source = keyValueFormat.generate "aria2.conf" cfg.settings;
    };
  };
}
