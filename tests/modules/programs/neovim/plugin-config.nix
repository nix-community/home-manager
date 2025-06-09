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

  nmt.script = ''
    vimout=$(mktemp)
    echo "redir >> /dev/stdout | echo g:hmExtraConfig | echo g:hmPlugins | redir END" \
      | ${pkgs.neovim}/bin/nvim -es -u "$TESTED/home-files/.config/nvim/init.lua" \
      > "$vimout" || true
    assertFileContains "$vimout" "HM_EXTRA_CONFIG"
    assertFileContains "$vimout" "HM_PLUGINS_CONFIG"

    initLua="$TESTED/home-files/.config/nvim/init.lua"
    assertFileContent "$initLua" ${./plugin-config.expected}
  '';
}
