{ pkgs, realPkgs, ... }:

{
  tests.stubs.wl-clipboard = { };

  programs.neovim = {
    enable = true;
    package = realPkgs.neovim-unwrapped;
    vimAlias = true;
    withNodeJs = false;
    withPython3 = true;
    withRuby = false;

    sideloadInitLua = true;

    extraPython3Packages = (
      ps: with ps; [
        jedi
        pynvim
      ]
    );

    # plugins without associated config should not trigger the creation of init.vim
    plugins = with pkgs.vimPlugins; [
      {
        plugin = vim-fugitive;
        type = "viml";
        config = ''
          let g:hmPluginVimlConfig = 'HM_PLUGIN_VIML_CONFIG'
        '';
      }
      {
        plugin = vim-sensible;
        type = "lua";
        config = ''
          vim.g.hmPluginLuaConfig = 'HM_PLUGIN_LUA_CONFIG'
        '';
      }
    ];

    extraConfig = ''
      let g:hmExtraConfig = 'HM_EXTRA_CONFIG'
    '';

    initLua = ''
      vim.g.hmInitLua = 'HM_INIT_LUA'
    '';
  };
  nmt.script = ''
    nvimFolder="home-files/.config/nvim"
    nvimBin="home-path/bin/nvim"
    export PATH="$TESTED/home-path/bin:$PATH"
    export HOME="$TMPDIR/hm-user"
    export XDG_CONFIG_HOME="$TESTED/home-files/.config"

    assertNeovimExpr() {
        local expr="$1"
        local expected_pattern="$2"
        local output=$(nvim -i NONE --headless -c "$expr" +q! 2>&1)
        local exit_code=$?

        if [ $exit_code -ne 0 ]; then
          echo "neovim command failed with code: $exit_code and output:"
          fail "$output"
        elif ! grep "$expected_pattern" <(echo -n "$output") ; then
          echo "Expression '$expr' doesn't match expected pattern '$expected_pattern'"
          echo "Output:"
          fail "$output"

          echo "'$output'"
        fi
    }

    assertPathNotExists "$nvimFolder/init.lua"

    assertNeovimExpr "echo g:hmPluginVimlConfig" "HM_PLUGIN_VIML_CONFIG"
    assertNeovimExpr "echo g:hmExtraConfig" "HM_EXTRA_CONFIG"
    assertNeovimExpr "echo g:hmExtraConfig" "HM_EXTRA_CONFIG"
    assertNeovimExpr "echo g:hmInitLua" "HM_INIT_LUA"
  '';
}
