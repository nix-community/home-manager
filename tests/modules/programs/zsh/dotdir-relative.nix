{ ... }: {
  config = {
    programs.zsh = {
      enable = true;
      dotDir = "subdir/subdir2";
    };

    test.stubs.zsh = { };

    nmt.script = "assertFileExists home-files/subdir/subdir2/.zshrc";
  };
}
