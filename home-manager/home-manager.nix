{
  pkgs ? import <nixpkgs> { },
  confPath,
  confAttr ? null,
  check ? true,
}:

let

  env = import ../modules {
    configuration =
      if confAttr == "" || confAttr == null then confPath else (import confPath).${confAttr};
    pkgs = pkgs;
    check = check;
  };

in
{
  inherit (env) activationPackage config;
}
