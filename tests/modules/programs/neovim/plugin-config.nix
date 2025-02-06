{ config, lib, pkgs, realPkgs, ... }:

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
    ];
    extraLuaPackages = [ pkgs.lua51Packages.luautf8 ];
  };

  _module.args.pkgs = lib.mkForce realPkgs;

  nmt.script = ''
    vimout=$out/nvim-output
    export HOME=$TESTED/home-files
    ${pkgs.neovim-unwrapped}/bin/nvim -i NONE -V3$out/log.txt +"redir >> $vimout | echo g:hmExtraConfig | echo g:hmPlugins | redir END" +'exit'
    assertFileContains "$vimout" "HM_EXTRA_CONFIG"
    assertFileContains "$vimout" "HM_PLUGINS_CONFIG"
  '';
}

