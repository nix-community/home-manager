{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.neovim;
in
{
  config = lib.mkIf cfg.enable {
    programs.neovim.initLua =
      lib.mkIf (lib.hasAttr "fennel" cfg.generatedConfigs && cfg.generatedConfigs.fennel != "")
        (
          lib.mkAfter ''
            -- user-associated fennel plugin config {{{
            require('fennel-plugins')
            -- }}}
          ''
        );

    xdg.configFile."nvim/lua/fennel-plugins.lua" =
      let
        compiledFennel =
          pkgs.runCommand "fennel-plugins.lua"
            {
              passAsFile = [ "fnlSrc" ];
              fnlSrc = cfg.generatedConfigs.fennel;
            }
            ''
              ${pkgs.luajitPackages.fennel}/bin/fennel --compile \
                "$fnlSrcPath" > $out
            '';
      in
      lib.mkIf (lib.hasAttr "fennel" cfg.generatedConfigs && cfg.generatedConfigs.fennel != "") {
        source = compiledFennel;
      };
  };
}
