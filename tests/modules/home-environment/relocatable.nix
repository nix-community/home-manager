{ pkgs, ... }:

{
  test.stubs = {
    hello = {
      name = "hello";
      buildScript = ''
        mkdir -p $out/bin
        touch $out/bin/hello
        chmod +x $out/bin/hello
      '';
      outPath = null;
    };
  };

  home.relocatable = true;

  home.packages = [
    pkgs.hello
  ];

  programs.bash.enable = true;

  programs.zsh.enable = true;

  programs.git = {
    enable = true;
    userName = "test";
  };

  nmt.script = ''
    assertFileIsExecutable home-path/bin/hello
  '';
}
