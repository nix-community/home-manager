{
  imports = [ ./stubs.nix ];

  programs.neovim = {
    enable = true;

    initLua = ''
      -- initLua
    '';
  };

  nmt.script = ''
    nvimFolder="home-files/.config/nvim"
    assertFileExists "$nvimFolder/init.lua"
    assertFileContains "$nvimFolder/init.lua" "python3_host_prog="
    assertFileContains "$nvimFolder/init.lua" "loaded_node_provider=0"
    assertFileContains "$nvimFolder/init.lua" "initLua"
  '';
}
