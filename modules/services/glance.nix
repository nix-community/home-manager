{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.glance;

  inherit (lib)
    mkEnableOption
    mkPackageOption
    mkOption
    mkIf
    getExe
    ;

  settingsFormat = pkgs.formats.yaml { };

  settingsFile = settingsFormat.generate "glance.yml" cfg.settings;

  configFilePath = "${config.xdg.configHome}/glance/glance.yml";
in
{
  meta.maintainers = [ pkgs.lib.maintainers.gepbird ];

  options.services.glance = {
    enable = mkEnableOption "glance";

    package = mkPackageOption pkgs "glance" { };

    settings = mkOption {
      inherit (settingsFormat) type;
      default = {
        pages = [
          {
            name = "Calendar";
            columns = [
              {
                size = "full";
                widgets = [ { type = "calendar"; } ];
              }
            ];
          }
        ];
      };
      example = {
        server.port = 5678;
        pages = [
          {
            name = "Home";
            columns = [
              {
                size = "full";
                widgets = [
                  { type = "calendar"; }
                  {
                    type = "weather";
                    location = "London, United Kingdom";
                  }
                ];
              }
            ];
          }
        ];
      };
      description = ''
        Configuration written to a yaml file that is read by glance. See
        <https://github.com/glanceapp/glance/blob/main/docs/configuration.md>
        for more.
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile."glance/glance.yml" = {
      source = settingsFile;
      onChange = mkIf pkgs.stdenv.hostPlatform.isDarwin ''
        /bin/launchctl kickstart -k "gui/$(id -u)/org.nix-community.home.glance" 2>/dev/null || true
      '';
    };

    launchd.agents.glance = mkIf (cfg.package != null) {
      enable = true;
      config = {
        ProgramArguments = [
          (getExe cfg.package)
          "--config"
          configFilePath
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/glance.err";
        StandardOutPath = "${config.home.homeDirectory}/Library/Logs/glance.log";
      };
    };

    systemd.user.services.glance = mkIf (cfg.package != null) {
      Unit = {
        Description = "Glance feed dashboard server";
        PartOf = [ "graphical-session.target" ];
        X-Restart-Triggers = [
          settingsFile
        ];
      };

      Install.WantedBy = [ "graphical-session.target" ];

      Service.ExecStart = "${getExe cfg.package} --config ${configFilePath}";
    };
  };
}
