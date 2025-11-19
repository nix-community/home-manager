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
      minimal ? false,
    }:
    import ../modules {
      inherit
        check
        extraSpecialArgs
        lib
        pkgs
        minimal
        ;
      configuration = {
        imports = modules ++ [
          {
            programs.home-manager.path = builtins.path {
              path = ../.;
              name = "source";
            };
          }
        ];

        nixpkgs = {
          config = lib.mkDefault pkgs.config;

          inherit (pkgs) overlays;
        };
      };
    };
}
