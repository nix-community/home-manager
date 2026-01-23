{
  imports = [ ./stubs.nix ];

  programs.neovim.enable = true;

  nmt.script = ''
    nvimFolder="home-files/.config/nvim"
    assertPathNotExists "$nvimFolder/init.lua"
  '';
}
