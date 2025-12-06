{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.services.gotify-desktop;
  tomlFormat = pkgs.formats.toml { };
in
{
  meta.maintainers = with lib.hm.maintainers; [
    joker9944
  ];

  options.services.gotify-desktop =
    let
      inherit (lib)
        mkEnableOption
        mkPackageOption
        mkOption
        literalExpression
        types
        ;
    in
    {
      enable = mkEnableOption "Gotify daemon to receive messages and forward them as desktop notifications";

      package = mkPackageOption pkgs "gotify-desktop" { };

      url = mkOption {
        type = types.str;
        example = "wss://gotify.example.com:8443";
        description = ''
          Gotify server websocket URL, use wss:// prefix for TLS, or ws:// for unencrypted.
        '';
      };

      token = mkOption {
        type = types.oneOf [
          types.str
          (types.submodule {
            options = {
              command = mkOption {
                type = types.str;
              };
            };
          })
        ];
        example = literalExpression ''
          "gotify-token"
          or
          { command = "''${lib.getExe pkgs.libsecret} lookup Title 'Gotify token'"; }
          or
          { command = "''${lib.getExe' pkgs.coreutils "cat"} /foo/bar/token"; }
        '';
        description = ''
          Secret Gotify client token.
          Either directly as string or as command for fetching client token.
        '';
      };

      settings = mkOption {
        inherit (tomlFormat) type;
        default = { };
        example = literalExpression ''
          {
            # optional, if true, deletes messages that have been handled, defaults to false
            gotify.auto_delete = true;

            # optional, ignores messages with priority lower than given value, defaults to 0
            notification.min_priority = 1;

            # optional, run the given command for each message, with the following environment variables set: GOTIFY_MSG_PRIORITY, GOTIFY_MSG_TITLE and GOTIFY_MSG_TEXT.
            action.on_msg_command = "/usr/bin/beep";
          }
        '';
        description = ''
          Configuration settings for gotify-desktop. All available options can be found here:
          <https://github.com/desbma/gotify-desktop/blob/master/README.md#configuration>
        '';
      };
    };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "services.gotify-desktop" pkgs lib.platforms.linux)
    ];

    services.gotify-desktop.settings = {
      gotify = { inherit (cfg) url token; };
    };

    xdg.configFile."gotify-desktop/config.toml".source =
      tomlFormat.generate "gotify-desktop-config.toml" cfg.settings;

    # Based on systemd service example provided by package
    # https://github.com/desbma/gotify-desktop/blob/521dbf4d175833b6338856248c7c6b383c1e5fa6/gotify-desktop.service
    systemd.user.services.gotify-desktop = {
      Unit = {
        Description = "Gotify daemon to send desktop notifications";
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "always";
        RestartSec = "5s";
      };

      Install.WantedBy = [ "graphical-session.target" ];
    };
  };
}
