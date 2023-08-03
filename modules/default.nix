{ modules
, pkgsPath
  # Whether to check that each option has a matching declaration.
, check ? true
  # Extra arguments passed to specialArgs.
, extraSpecialArgs ? { }
}:let


    lib = import ./lib/stdlib-extended.nix (import "${pkgsPath}/lib");

    collectFailed = cfg:
      map (x: x.message) (lib.filter (x: !x.assertion) cfg.assertions);

    showWarnings = res:
      let f = w: builtins.trace "[1;31mwarning: ${w}[0m";
      in lib.fold f res res.config.warnings;

    hmModules = import ./all-modules.nix { inherit check lib pkgsPath; };

    rawModule = lib.evalModules {
      specialArgs = extraSpecialArgs;
      modules = modules ++ hmModules;
    };

    module = showWarnings (let
      failed = collectFailed rawModule.config;
      failedStr = lib.concatStringsSep "\n" (map (x: "- ${x}") failed);
    in if failed == [ ] then
      rawModule
    else
      throw ''

        Failed assertions:
        ${failedStr}'');
  in {
    inherit (module) options config;

    inherit (module.config.home) activationPackage;

    # For backwards compatibility. Please use activationPackage instead.
    activation-script = module.config.home.activationPackage;

    newsDisplay = rawModule.config.news.display;
    newsEntries = lib.sort (a: b: a.time > b.time)
      (lib.filter (a: a.condition) rawModule.config.news.entries);

    inherit (module._module.args) pkgs;
  }
