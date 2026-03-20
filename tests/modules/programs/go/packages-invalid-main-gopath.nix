{ config, ... }:

{
  programs.go = {
    enable = true;
    env.GOPATH = [
      "/not/my/home/mygo"
      "/another/go"
      "/yet/another/go"
    ];

    packages = {
      "golang.org/x/text" = ./packages/text;
      "golang.org/x/time" = ./packages/time;
    };
  };
  test.asserts.assertions.expected = [
    "The first element of `programs.go.env.GOPATH must be an absolute path that points to a directory inside ${config.home.homeDirectory} if `programs.go.packages` is set."
  ];
}
