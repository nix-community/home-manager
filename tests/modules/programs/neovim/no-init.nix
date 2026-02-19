{ pkgs, ... }:

{
  imports = [ ./stubs.nix ];

  programs.neovim = {
    enable = true;
    vimAlias = true;
    withNodeJs = false;
    withPython3 = true;
    withRuby = false;

    extraPython3Packages = (
      ps: with ps; [
        jedi
        pynvim
      ]
    );

    # plugins without associated config should not trigger the creation of init.vim
    plugins = with pkgs.vimPlugins; [
      vim-fugitive
      { plugin = vim-sensible; }
    ];
  };
  nmt.script = ''
    nvimFolder="home-files/.config/nvim"
    assertPathNotExists "$nvimFolder/init.vim"
    assertFileExists "$nvimFolder/init.lua"
    assertFileContains "$nvimFolder/init.lua" "python3_host_prog="
    assertFileContains "$nvimFolder/init.lua" "loaded_node_provider=0"
  '';
}
