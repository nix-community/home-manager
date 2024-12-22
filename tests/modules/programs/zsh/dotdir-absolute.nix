{ config, ... }: {
  config = {
    programs.zsh = {
      enable = true;
      dotDir = "${config.home.homeDirectory}/subdir/subdir2";
    };

    test.stubs.zsh = { };

    nmt.script = "assertFileExists home-files/subdir/subdir2/.zshrc";
  };
}
