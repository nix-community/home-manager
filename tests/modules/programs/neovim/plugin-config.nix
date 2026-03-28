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
        # testing viml config
        config = ''
          let g:hmPlugins='HM_PLUGINS_CONFIG'
        '';
      }
      {
        plugin = vim-nix;
        # testing lua config
        type = "lua";
        config = ''
          function HM_PLUGIN_LUA_CONFIG ()
          end
        '';
      }
      {
        # to test passthru.initLua is taken into account
        plugin = unicode-vim;
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
      echo "redir >> /dev/stdout | echo g:hmExtraConfig | echo g:hmPlugins | echo g:Unicode_data_directory | redir END" \
        | ${pkgs.neovim}/bin/nvim -es -u "$TESTED/home-files/.config/nvim/init.lua" \
        > "$vimout" || true
      assertFileContains "$vimout" "HM_EXTRA_CONFIG"
      assertFileContains "$vimout" "HM_PLUGINS_CONFIG"
      # testing that unicode-vim's value is echoed
      assertFileContains "$vimout" "autoload/unicode"

      initLua="$TESTED/home-files/.config/nvim/init.lua"
      assertFileContent $(normalizeStorePaths "$initLua") ${./plugin-config.expected}

      # Verify generatedConfigs evaluated properly (issue #8371)
      echo "Lua config length: ${toString (builtins.stringLength luaConfig)}"
      echo "Viml config length: ${toString (builtins.stringLength vimlConfig)}"
    '';
}
