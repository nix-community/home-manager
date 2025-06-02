{ lib }:
{
  hm = (import ../modules/lib/stdlib-extended.nix lib).hm;

  homeManagerConfiguration =
    {
      check ? true,
      extraSpecialArgs ? { },
      lib ? pkgs.lib,
      modules ? [ ],
      pkgs,
    }:
    import ../modules {
      inherit
        check
        extraSpecialArgs
        lib
        pkgs
        ;
      configuration =
        { ... }:
        {
          imports = modules ++ [ { programs.home-manager.path = "${../.}"; } ];

          nixpkgs = {
            config = lib.mkDefault pkgs.config;

            inherit (pkgs) overlays;
          };
        };
    };
}
