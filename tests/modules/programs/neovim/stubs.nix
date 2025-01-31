{ lib, pkgs, ... }:

{
  test.stubs = {
    neovim-unwrapped = {
      name = "neovim-unwrapped";
      outPath = null;
      buildScript = ''
        mkdir -p $out/bin $out/share/applications
        echo "Name=Neovim" > $out/share/applications/nvim.desktop

        cp ${pkgs.writeShellScript "nvim" "exit 0"} $out/bin/nvim
        chmod +x $out/bin/nvim
      '';
      extraAttrs = {
        lua = pkgs.writeTextDir "nix-support/utils.sh" ''
          function _addToLuaPath() {
            return 0
          }
        '';

        meta = let stub = "stub";
        in {
          description = stub;
          longDescription = stub;
          homepage = stub;
          mainProgram = stub;
          license = [ stub ];
          maintainers = [ stub ];
          platforms = lib.platforms.all;
        };
      };
    };
  };
}
