{ pkgs, config, ... }:

{
  programs.go = {
    enable = true;
    env = {
      CXX = "g++";
      GCCGO = "gccgo";
      GOAMD64 = "v1";
      GOARCH = "amd64";
      GOAUTH = "netrc";
    };
  };

  nmt.script =
    let
      goCfgDir = if !pkgs.stdenv.isDarwin then ".config/go" else "Library/Application\ Support/go";
    in
    ''
      assertFileExists "home-files/${goCfgDir}/env"
      assertFileContent "home-files/${goCfgDir}/env" \
        ${./env-suboptions-unset}
    '';
}
