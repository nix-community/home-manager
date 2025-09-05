{ config, ... }:

{
  programs.go = {
    enable = true;
    env.GOPATH = [
      "${config.home.homeDirectory}/mygo"
      "/another/go"
      "/yet/another/go"
    ];

    packages = {
      "golang.org/x/text" = ./packages/text;
      "golang.org/x/time" = ./packages/time;
    };
  };

  nmt.script = ''
    assertFileExists home-files/mygo/src/golang.org/x/text/main.go
    assertFileExists home-files/mygo/src/golang.org/x/time/main.go
  '';
}
