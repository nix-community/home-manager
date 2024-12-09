{ ... }:

{
  programs.neovide = {
    enable = true;

    settings = {
      fork = false;
      frame = "full";
      idle = true;
      maximized = false;
      neovim-bin = "/usr/bin/nvim";
      no-multigrid = false;
      srgb = false;
      tabs = true;
      theme = "auto";
      title-hidden = true;
      vsync = true;
      wsl = false;

      font = {
        normal = [ ];
        size = 14.0;
      };
    };
  };

  test.stubs.neovide = { };

  nmt.script = ''
    assertFileExists home-files/.config/neovide/config.toml
    assertFileContent home-files/.config/neovide/config.toml ${./expected.toml}
  '';
}
