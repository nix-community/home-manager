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
    withRuby = false;
    plugins = with pkgs.vimPlugins; [
      {
        plugin = vim-nix;
        type = "fennel";
        config = ''(vim.cmd "let g:hmFennelPlugin='HM_FENNEL_PLUGIN'")'';
      }
    ];
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script =
    let
      fnlConfig = config.programs.neovim.generatedConfigs.fennel;
    in
    ''
      vimout=$(mktemp)

      export PATH="$TESTED/home-path/bin:$PATH"
      export HOME=$TMPDIR/hm-user
      export XDG_CONFIG_HOME="$TESTED/home-files/.config"
      initLua="$TESTED/home-files/.config/nvim/init.lua"

      assertFileContains "$initLua" "require('fennel-plugins')"
      assertFileContent $(normalizeStorePaths "$initLua") ${./plugin-fennel-config.expected}

      echo "redir >> /dev/stdout | echo g:hmFennelPlugin | redir END" \
        | nvim -es -i NONE -u "$initLua" \
        > "$vimout" || true
      assertFileContains "$vimout" "HM_FENNEL_PLUGIN"

      echo "Fennel config length: ${toString (builtins.stringLength fnlConfig)}"
    '';
}
