{
  programs.go = {
    enable = true;
    packages = {
      "golang.org/x/text" = ./packages/text;
      "golang.org/x/time" = ./packages/time;
    };
  };

  nmt.script = ''
    assertFileExists home-files/go/src/golang.org/x/text/main.go
    assertFileExists home-files/go/src/golang.org/x/time/main.go
  '';
}
