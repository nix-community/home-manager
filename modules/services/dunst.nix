{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.dunst;

  eitherStrBoolIntList = with types; either str (either bool (either int (listOf str)));

  toDunstIni = generators.toINI {
    mkKeyValue = key: value:
    let
      value' =
        if isBool value then (if value then "yes" else "no")
        else if isString value then "\"${value}\""
        else toString value;
    in
      "${key}=${value'}";
  };

  themeType = types.submodule {
    options = {
      package = mkOption {
        type = types.package;
        example = literalExample "pkgs.gnome3.adwaita-icon-theme";
        description = "Package providing the theme.";
      };

      name = mkOption {
        type = types.str;
        example = "Adwaita";
        description = "The name of the theme within the package.";
      };

      size = mkOption {
        type = types.str;
        default = "32x32";
        example = "16x16";
        description = "The desired icon size.";
      };
    };
  };

  hicolorTheme = {
    package = pkgs.hicolor_icon_theme;
    name = "hicolor";
    size = "32x32";
  };

in

{
  meta.maintainers = with maintainers; [ rycee ma27 ];

  options = {
    services.dunst = {
      enable = mkEnableOption "the dunst notification daemon";

      iconTheme = mkOption {
        type = themeType;
        default = hicolorTheme;
        description = "Set the icon theme.";
      };

      dunstrc = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          Path to <literal>.dunstrc</literal>.
          Mutually exclusive with <literal>services.dunst.settings</literal>.
        '';
      };

      settings = mkOption {
        type = with types; attrsOf (attrsOf eitherStrBoolIntList);
        default = {};
        description = "Configuration written to ~/.config/dunstrc";
        example = literalExample ''
          {
            global = {
              geometry = "300x5-30+50";
              transparency = 10;
              frame_color = "#eceff1";
              font = "Droid Sans 9";
            };

            urgency_normal = {
              background = "#37474f";
              foreground = "#eceff1";
              timeout = 10;
            };
          };
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.dunstrc != null -> cfg.settings == {};
        message = ''
          The options `services.dunst.settings` and `services.dunst.dunstrc`
          are mutually exclusive.
        '';
      }
    ];

    xdg.dataFile."dbus-1/services/org.knopwob.dunst.service".source =
      "${pkgs.dunst}/share/dbus-1/services/org.knopwob.dunst.service";

    services.dunst = mkIf (cfg.dunstrc == null) {
      settings.global.icon_path = let
        useCustomTheme =
          cfg.iconTheme.package != hicolorTheme.package
          || cfg.iconTheme.name != hicolorTheme.name
          || cfg.iconTheme.size != hicolorTheme.size;

        basePaths = [
          "/run/current-system/sw"
          config.home.profileDirectory
          cfg.iconTheme.package
        ] ++ optional useCustomTheme hicolorTheme.package;

        themes =
          [
            cfg.iconTheme
          ] ++ optional useCustomTheme (
            hicolorTheme // { size = cfg.iconTheme.size; }
          );

        categories = [
          "actions"
          "animations"
          "apps"
          "categories"
          "devices"
          "emblems"
          "emotes"
          "filesystem"
          "intl"
          "mimetypes"
          "places"
          "status"
          "stock"
        ];
      in
        concatStringsSep ":" (
          concatMap (theme:
            concatMap (basePath:
              map (category:
                "${basePath}/share/icons/${theme.name}/${theme.size}/${category}"
              ) categories
            ) basePaths
          ) themes
        );
    };

    systemd.user.services.dunst = {
      Unit = {
        Description = "Dunst notification daemon";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Type = "dbus";
        BusName = "org.freedesktop.Notifications";
        ExecStart = "${pkgs.dunst}/bin/dunst";
      };
    };

    xdg.configFile."dunst/dunstrc" = {
      text = if cfg.dunstrc != null
        then builtins.readFile cfg.dunstrc
        else toDunstIni cfg.settings;
      onChange = ''
        pkillVerbose=""
        if [[ -v VERBOSE ]]; then
          pkillVerbose="-e"
        fi
        $DRY_RUN_CMD ${pkgs.procps}/bin/pkill -u $USER $pkillVerbose dunst || true
        unset pkillVerbose
      '';
    };
  };
}
