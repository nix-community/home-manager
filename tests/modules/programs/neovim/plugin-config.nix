{
  config,
  lib,
  pkgs,
  realPkgs,
  ...
}:

lib.mkIf config.test.enableBig {
  programs.neovim = {
    enable = true;
    extraConfig = ''
      let g:hmExtraConfig='HM_EXTRA_CONFIG'
    '';
    plugins = with pkgs.vimPlugins; [
      vim-nix
      {
        plugin = vim-commentary;
        config = ''
          let g:hmPlugins='HM_PLUGINS_CONFIG'
        '';
      }
      {
        plugin = vim-nix;
        type = "lua";
        config = ''
          function HM_PLUGIN_LUA_CONFIG ()
          end
        '';
      }
    ];
    extraLuaPackages = ps: [ ps.luautf8 ];
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script =
    let
      # Force evaluation of generatedConfigs.
      luaConfig = config.programs.neovim.generatedConfigs.lua;
      vimlConfig = config.programs.neovim.generatedConfigs.viml;
    in
    ''
      vimout=$(mktemp)
      echo "redir >> /dev/stdout | echo g:hmExtraConfig | echo g:hmPlugins | redir END" \
        | ${pkgs.neovim}/bin/nvim -es -u "$TESTED/home-files/.config/nvim/init.lua" \
        > "$vimout" || true
      assertFileContains "$vimout" "HM_EXTRA_CONFIG"
      assertFileContains "$vimout" "HM_PLUGINS_CONFIG"

      initLua="$TESTED/home-files/.config/nvim/init.lua"

      # Provider configuration must be present
      assertFileContains "$initLua" "python3_host_prog="
      assertFileContains "$initLua" "ruby_host_prog="
      assertFileContains "$initLua" "loaded_node_provider=0"
      assertFileContains "$initLua" "loaded_perl_provider=0"
      assertFileContains "$initLua" "loaded_python_provider=0"

      # Lua package path, VimScript source, and plugin config must be present
      assertFileContains "$initLua" "package.path"
      assertFileContains "$initLua" "nvim-init-home-manager.vim"
      assertFileContains "$initLua" "HM_PLUGIN_LUA_CONFIG"

      # Verify generatedConfigs evaluated properly (issue #8371)
      echo "Lua config length: ${toString (builtins.stringLength luaConfig)}"
      echo "Viml config length: ${toString (builtins.stringLength vimlConfig)}"
    '';
}
