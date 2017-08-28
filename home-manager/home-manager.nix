{ pkgs ? import <nixpkgs> {}, confPath, confAttr }:

let
  env = import <home-manager> {
    configuration =
      let
        conf = import confPath;
      in
        if confAttr == "" then conf else conf.${confAttr};
    pkgs = pkgs;
  };
in
  {
    inherit (env) activationPackage;
  }
