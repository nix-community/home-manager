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
              fnlSrc = cfg.generatedConfigs.fennel;
              __structuredAttrs = true;
            }
            ''
              ${lib.getExe pkgs.jq} -rj '.fnlSrc' "$NIX_ATTRS_JSON_FILE" > fnlSrc
              ${lib.getExe cfg.package.lua.pkgs.fennel} --compile fnlSrc > "$out"
            '';
      in
      lib.mkIf (lib.hasAttr "fennel" cfg.generatedConfigs && cfg.generatedConfigs.fennel != "") {
        source = compiledFennel;
      };
  };
}
