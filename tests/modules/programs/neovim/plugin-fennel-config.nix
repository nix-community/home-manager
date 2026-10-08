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

  nmt.script = ''
    export PATH="$TESTED/home-path/bin:$PATH"
    export HOME=$TMPDIR/hm-user
    export XDG_CONFIG_HOME="$TESTED/home-files/.config"
    initLua="$TESTED/home-files/.config/nvim/init.lua"

    assertFileContains "$initLua" "require('fennel-plugins')"

    vimout=$(mktemp)
    nvim --headless +'lua print(vim.g.hmFennelPlugin)' +q! 2&> $vimout
    assertFileContains "$vimout" "HM_FENNEL_PLUGIN"
  '';
}
