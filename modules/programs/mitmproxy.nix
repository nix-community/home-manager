{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.programs.mitmproxy;

  settingsFormat = pkgs.formats.yaml { };
in
{
  meta.maintainers = [ lib.maintainers.keshavkrishna ];

  options.programs.mitmproxy = {
    enable = lib.mkEnableOption "mitmproxy, an interactive HTTPS proxy";

    package = lib.mkPackageOption pkgs "mitmproxy" { nullable = true; };

    settings = lib.mkOption {
      inherit (settingsFormat) type;
      default = { };
      defaultText = lib.literalExpression "{ }";
      example = lib.literalExpression ''
        {
          listen_port = 8081;
          ssl_insecure = true;
          anticache = true;
        }
      '';
      description = ''
        Options written to {file}`~/.mitmproxy/config.yaml`. This
        configuration file is shared by all mitmproxy tools (mitmproxy,
        mitmweb, and mitmdump). See
        <https://docs.mitmproxy.org/stable/concepts-options/>
        for the available options. Note that mitmproxy always reads its
        configuration from `~/.mitmproxy` and does not honor XDG
        directories.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = mkIf (cfg.package != null) [ cfg.package ];

    home.file.".mitmproxy/config.yaml" = mkIf (cfg.settings != { }) {
      source = settingsFormat.generate "mitmproxy-config" cfg.settings;
    };
  };
}
