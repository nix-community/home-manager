{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.xsession.windowManager.awesome;
  awesome = cfg.package;
  getLuaPath = lib: dir: "${lib}/${dir}/lua/${awesome.lua.luaversion}";
  makeSearchPath = lib.concatMapStrings (
    path: " --search ${getLuaPath path "share"}" + " --search ${getLuaPath path "lib"}"
  );

in
{
  options = {
    xsession.windowManager.awesome = {
      enable = lib.mkEnableOption "Awesome window manager";

      package = mkOption {
        type = types.package;
        default = pkgs.awesome;
        defaultText = lib.literalExpression "pkgs.awesome";
        description = "Package to use for running the Awesome WM.";
      };

      luaModules = mkOption {
        default = [ ];
        type = types.listOf types.package;
        description = ''
          List of lua packages available for being
          used in the Awesome configuration.
        '';
        example = lib.literalExpression "[ pkgs.luaPackages.vicious ]";
      };

      noArgb = mkOption {
        default = false;
        type = types.bool;
        description = ''
          Disable client transparency support, which can be greatly
          detrimental to performance in some setups
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      (lib.hm.assertions.assertPlatform "xsession.windowManager.awesome" pkgs lib.platforms.linux)
    ];

    home.packages = [ awesome ];

    xsession.windowManager.command =
      "${awesome}/bin/awesome "
      + lib.optionalString cfg.noArgb "--no-argb "
      + makeSearchPath cfg.luaModules;
  };
}
