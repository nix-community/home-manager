{ pkgs ? import <nixpkgs> { }, confPath, confAttr ? null, check ? true
, newsReadIdsFile ? null }:

let
  inherit (pkgs.lib)
    concatMapStringsSep fileContents filter length optionalString removeSuffix
    replaceStrings splitString;

  env = import ../modules {
    configuration = if confAttr == "" || confAttr == null then
      confPath
    else
      (import confPath).${confAttr};
    pkgs = pkgs;
    check = check;
  };

in { inherit (env) activationPackage config; }
