{ pkgsPath ? <nixpkgs>, confPath, confAttr ? null, check ? true
, newsReadIdsFile ? null }:

let
  env = import ../modules {

    inherit pkgsPath check;

    modules = [
      (if confAttr == "" || confAttr == null then
        confPath
      else
        (import confPath).${confAttr})
    ];

  };
in {
  inherit (env) config;
  inherit (env.config.home) activationPackage;
}
