{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.gtklock;

  settingsFormat = pkgs.formats.ini {
    listToValue = builtins.concatStringsSep ";";
  };
in
{
  meta.maintainers = [ lib.hm.maintainers.olmokramer ];

  options.programs.gtklock = {
    enable = lib.mkEnableOption "gtklock";

    package = lib.mkPackageOption pkgs "gtklock" { };

    settings = lib.mkOption {
      inherit (settingsFormat) type;
      default = { };
      description = ''
        Gtklock settings. See <https://github.com/jovanlanik/gtklock/wiki#config>
        for supported values.
      '';
      example = {
        idle-hide = true;
        idle-timeout = 60;
        start-hidden = true;
      };
    };

    modulePackages = lib.mkOption {
      type = lib.types.listOf lib.types.package;
      default = [ ];
      description = ''
        List of packages containing extra modules to load. All `.so` files in
        the package's `lib/gtklock` directory will be included in the
        configuration.
      '';
      example = lib.literalExpression ''
        [
          pkgs.gtklock-playerctl-module
          pkgs.gtklock-virtkb-module
        ]
      '';
    };

    style = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = ''
        CSS to add to the stylesheet. See
        <https://github.com/jovanlanik/gtklock/wiki#styling>
        for more information.
      '';
      example = lib.literalExpression ''
        '''
          window {
            background-color: red;
            color: white;
          }
        '''
      '';
    };

    background = {
      path = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = ''
          Path to a background image to use. By default the image is centered
          and stretched to fill the entire screen.
        '';
        example = lib.literalExpression ''
          ./background.jpg
        '';
      };

      mode = lib.mkOption {
        type = lib.types.str;
        default = "center/cover";
        description = ''
          Extra properties to add to the `background` shorthand CSS rule. See
          <https://docs.gtk.org/gtk3/css-properties.html#background-properties>
          for details.
        '';
        example = "center/50% repeat";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.gtklock" pkgs lib.platforms.linux)
    ];

    home.packages = [ cfg.package ];

    programs.gtklock = {
      style =
        let
          inherit (cfg.background) path mode;
        in
        lib.mkIf (path != null) (
          lib.mkAfter ''
            window {
              background: url("file://${cfg.background.path}") ${mode};
            }
          ''
        );

      settings = lib.mkMerge [
        (lib.mkIf (cfg.modulePackages != [ ]) {
          main.modules =
            let
              isSoFile = fileName: fileType: fileType == "regular" && lib.hasSuffix ".so" fileName;

              getSoFiles =
                pkg:
                let
                  moduleDir = "${pkg}/lib/gtklock";
                  allFiles = builtins.readDir moduleDir;
                  soFiles = lib.filterAttrs isSoFile allFiles;
                in
                lib.mapAttrsToList (name: _: "${moduleDir}/${name}") soFiles;
            in
            lib.concatMap getSoFiles cfg.modulePackages;
        })

        (lib.mkIf (lib.trim cfg.style != "") {
          main.style = "${pkgs.writeText "gtklock-style.css" cfg.style}";
        })
      ];
    };

    xdg.configFile = lib.mkIf (cfg.settings != { }) {
      "gtklock/config.ini".source = settingsFormat.generate "gtklock-config.ini" cfg.settings;
    };
  };
}
