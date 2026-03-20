{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.mc;
  type = (pkgs.formats.ini { }).type;
in
{
  options.programs.mc = {
    enable = lib.mkEnableOption "Midnight Commander";

    package = lib.mkPackageOption pkgs "mc" { nullable = true; };

    settings = lib.mkOption {
      inherit type;
      default = { };
      description = ''
        Settings for `mc/ini` file.

        Any missing settings will fall back to the system default.
      '';
      example = {
        Panels = {
          show_dot_files = false;
        };
      };
    };

    keymapSettings = lib.mkOption {
      inherit type;
      default = { };
      description = ''
        Settings for `mc/mc.keymap` file.

        Any missing settings will fall back to the system default.
      '';
      example = {
        panel = {
          Up = "up;ctrl-k";
        };
      };
    };

    extensionSettings = lib.mkOption {
      inherit type;
      default = { };
      description = ''
        Settings for `mc/mc.ext.ini` file. This setting completely replaces the default `/etc/mc/mc.ext.ini`.

        Midnight Commander does not merge this file with the system default,
        so you should copy the original if you want to preserve default behavior and add your changes there.
      '';
      example = {
        EPUB = {
          Shell = ".epub";
          Open = "fbreader %f &";
        };
      };
    };

    panelsSettings = lib.mkOption {
      inherit type;
      default = { };
      description = ''
        Settings for `mc/panels` file.

        Any missing settings will fall back to the system default.
      '';
      example = {
        Dirs = {
          current_is_left = false;
          other_dir = "/home";
        };
      };
    };

    fileHighlightSettings = lib.mkOption {
      inherit type;
      default = { };
      description = ''
        Settings for `mc/filehighlight.ini` file. This setting completely replaces the default `/etc/mc/filehighlight.ini`.

        Midnight Commander does not merge this file with the system default, so you should copy the original if you want to preserve default behavior
        and add your changes there.
      '';
      example = {
        lua = {
          extensions = "lua;luac";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf (cfg.package != null) [ cfg.package ];

    xdg.configFile = {
      "mc/ini" = lib.mkIf (cfg.settings != { }) {
        text = lib.generators.toINI { } cfg.settings;
      };
      "mc/mc.keymap" = lib.mkIf (cfg.keymapSettings != { }) {
        text = lib.generators.toINI { } cfg.keymapSettings;
      };
      "mc/mc.ext.ini" = lib.mkIf (cfg.extensionSettings != { }) {
        text = lib.generators.toINI { } cfg.extensionSettings;
      };
      "mc/panels.ini" = lib.mkIf (cfg.panelsSettings != { }) {
        text = lib.generators.toINI { } cfg.panelsSettings;
      };
      "mc/filehighlight.ini" = lib.mkIf (cfg.fileHighlightSettings != { }) {
        text = lib.generators.toINI { } cfg.fileHighlightSettings;
      };
    };
  };
}
