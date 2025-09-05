{
  lib,
  options,
  pkgs,
  config,
  ...
}:

{
  programs.go = {
    enable = true;
    goPath = "mygo";
    extraGoPaths = [
      "another/go"
      "yet/another/go"
    ];
    goBin = ".local/bin.go";
    goPrivate = [
      "*.corp.example.com"
      "rsc.io/private"
    ];
  };

  test.asserts.warnings.expected = [
    "The option `programs.go.goPrivate' defined in ${lib.showFiles options.programs.go.goPrivate.files} has been renamed to `programs.go.env.GOPRIVATE'."
    "The option `programs.go.goBin' defined in ${lib.showFiles options.programs.go.goBin.files} has been changed to `programs.go.env.GOBIN' that has a different type. Please read `programs.go.env.GOBIN' documentation and update your configuration accordingly."
    "The option `programs.go.extraGoPaths' defined in ${lib.showFiles options.programs.go.extraGoPaths.files} has been changed to `programs.go.env.GOPATH' that has a different type. Please read `programs.go.env.GOPATH' documentation and update your configuration accordingly."
    "The option `programs.go.goPath' defined in ${lib.showFiles options.programs.go.goPath.files} has been changed to `programs.go.env.GOPATH' that has a different type. Please read `programs.go.env.GOPATH' documentation and update your configuration accordingly."
  ];

  nmt.script =
    let
      goCfgDir = if !pkgs.stdenv.isDarwin then ".config/go" else "Library/Application\ Support/go";
    in
    ''
      assertFileExists "home-files/${goCfgDir}/env"
      assertFileContent "home-files/${goCfgDir}/env" \
        ${./env-old-options}
    '';
}
