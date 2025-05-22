{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    literalExpression
    mkEnableOption
    mkOption
    types
    ;

  cfg = config.programs.sketchybar;
in
{
  meta.maintainers = [ lib.maintainers.khaneliman ];

  options.programs.sketchybar = {
    enable = mkEnableOption "sketchybar";

    package = lib.mkPackageOption pkgs "sketchybar" { };

    finalPackage = mkOption {
      type = types.package;
      readOnly = true;
      internal = true;
      description = "Resulting customized sketchybar package.";
    };

    configType = mkOption {
      type = types.enum [
        "bash"
        "lua"
      ];
      default = "bash";
      description = ''
        The type of configuration to generate.

        Set to "bash" to use the standard bash configuration.
        Set to "lua" to use the Lua configuration via SbarLua.
      '';
    };

    config = mkOption {
      type = with types; nullOr (either lines path);
      default = "";
      example = literalExpression ''
        # Bash example
        #!/usr/bin/env bash

        # Define colors
        export COLOR_BLACK="0xff181926"
        export COLOR_WHITE="0xffcad3f5"

        # Configure bar
        sketchybar --bar height=32 \
                        position=top \
                        padding_left=10 \
                        padding_right=10 \
                        color=$COLOR_BLACK

        # Configure default values
        sketchybar --default icon.font="SF Pro:Bold:14.0" \
                            icon.color=$COLOR_WHITE \
                            label.font="SF Pro:Bold:14.0" \
                            label.color=$COLOR_WHITE

        # Add items to the bar
        sketchybar --add item clock right \
                  --set clock script="date '+%H:%M'" \
                              update_freq=10

        # Update the bar
        sketchybar --update
      '';
      description = ''
        The complete sketchybar configuration content.
        This should be written in the language specified by configType (bash or lua).

        The appropriate shebang will be automatically added.
      '';
    };

    sbarLuaPackage = lib.mkPackageOption pkgs "sbarlua" {
      nullable = true;
      extraDescription = "Required when using a lua configuration.";
    };

    luaPackage = lib.mkPackageOption pkgs "lua5_4" {
      nullable = true;
      extraDescription = "Lua interpreter to use when configType is lua.";
    };

    extraLuaPackages = mkOption {
      type = with types; functionTo (listOf package);
      default = _: [ ];
      defaultText = literalExpression "ps: [ ]";
      example = literalExpression "luaPkgs: with luaPkgs; [ luautf8 ]";
      description = ''
        The extra Lua packages required for your plugins to work.
        This option accepts a function that takes a Lua package set as an argument,
        and selects the required Lua packages from this package set.
        See the example for more info.
      '';
    };

    extraPackages = mkOption {
      type = with lib.types; listOf package;
      default = [ ];
      example = literalExpression "[ pkgs.jq ]";
      description = ''
        Extra packages to add to PATH for the sketchybar service.
      '';
    };

    service = {
      enable = mkEnableOption "sketchybar service" // {
        default = true;
      };

      errorLogFile = mkOption {
        type = with lib.types; nullOr (either path str);
        default = "${config.home.homeDirectory}/Library/Logs/sketchybar/sketchybar.err.log";
        defaultText = lib.literalExpression "\${config.home.homeDirectory}/Library/Logs/sketchybar/sketchybar.err.log";
        example = "/Users/khaneliman/Library/Logs/sketchybar.log";
        description = "Absolute path to log all stderr output.";
      };

      outLogFile = mkOption {
        type = with lib.types; nullOr (either path str);
        default = "${config.home.homeDirectory}/Library/Logs/sketchybar/sketchybar.out.log";
        defaultText = lib.literalExpression "\${config.home.homeDirectory}/Library/Logs/sketchybar/sketchybar.out.log";
        example = "/Users/khaneliman/Library/Logs/sketchybar.log";
        description = "Absolute path to log all stdout output.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "programs.sketchybar" pkgs lib.platforms.darwin)
      {
        assertion = !(cfg.configType == "lua" && cfg.sbarLuaPackage == null);
        message = "When configType is set to \"lua\", service.sbarLuaPackage must be specified";
      }
    ];

    programs.sketchybar.finalPackage =
      let
        resolvedExtraLuaPackages = cfg.extraLuaPackages pkgs.lua54Packages;

        pathPackages =
          [ cfg.package ]
          ++ cfg.extraPackages
          ++ lib.optional (cfg.configType == "lua" && cfg.luaPackage != null) cfg.luaPackage;

        luaPaths = lib.filter (x: x != "") [
          (lib.optionalString (cfg.configType == "lua" && resolvedExtraLuaPackages != [ ]) (
            lib.concatMapStringsSep ";" pkgs.lua54Packages.getLuaPath resolvedExtraLuaPackages
          ))
          (lib.optionalString (cfg.configType == "lua" && cfg.sbarLuaPackage != null) (
            pkgs.lua54Packages.getLuaPath cfg.sbarLuaPackage
          ))
          (lib.optionalString (cfg.configType == "lua" && cfg.config != null && cfg.config.source != null) (
            let
              configDir = "${config.xdg.configHome}/sketchybar";
            in
            "${configDir}/?.lua;${configDir}/?/init.lua;${configDir}/?/?.lua"
          ))
        ];

        luaCPaths = lib.filter (x: x != "") [
          (lib.optionalString (cfg.configType == "lua" && resolvedExtraLuaPackages != [ ]) (
            lib.concatMapStringsSep ";" pkgs.lua54Packages.getLuaCPath resolvedExtraLuaPackages
          ))
          (lib.optionalString (cfg.configType == "lua" && cfg.sbarLuaPackage != null) (
            pkgs.lua54Packages.getLuaCPath cfg.sbarLuaPackage
          ))
        ];

        makeWrapperArgs = lib.flatten (
          lib.filter (x: x != [ ]) [
            (lib.optional (pathPackages != [ ]) [
              "--prefix"
              "PATH"
              ":"
              "${lib.makeBinPath pathPackages}"
            ])

            (lib.optional (luaPaths != [ ]) [
              "--prefix"
              "LUA_PATH"
              ";"
              "${lib.concatStringsSep ";" luaPaths}"
            ])

            (lib.optional (luaCPaths != [ ]) [
              "--prefix"
              "LUA_CPATH"
              ";"
              "${lib.concatStringsSep ";" luaCPaths}"
            ])
          ]
        );

        hasWrapperArgs = makeWrapperArgs != [ ];
      in
      if hasWrapperArgs then
        pkgs.symlinkJoin {
          name = "sketchybar";
          paths = [ cfg.package ];
          nativeBuildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/sketchybar ${lib.escapeShellArgs makeWrapperArgs}
          '';
        }
      else
        cfg.package;

    home.packages = [ cfg.finalPackage ];

    xdg.configFile."sketchybar/sketchybarrc".source = lib.mkIf (cfg.config != "") (
      pkgs.writeTextFile {
        name = "sketchybarrc";
        text =
          if cfg.configType == "lua" then
            ''
              #!/usr/bin/env lua
              -- Generated by home-manager
              ${cfg.config}
            ''
          else
            ''
              #!/usr/bin/env bash
              # Generated by home-manager
              ${cfg.config}
            '';
        executable = true;
      }
    );

    launchd.agents.sketchybar = {
      enable = cfg.service.enable;
      config = {
        Program = lib.getExe cfg.finalPackage;
        ProcessType = "Interactive";
        KeepAlive = true;
        RunAtLoad = true;
        StandardErrorPath = cfg.service.errorLogFile;
        StandardOutPath = cfg.service.outLogFile;
      };
    };
  };
}
