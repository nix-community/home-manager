{ pkgs, ... }:
{
  programs.nix-search-tv = {
    enable = true;

    settings = {
      indexes = [
        "home-manager"
        "nixos"
        "nixpkgs"
      ];

      experimental = {
        render_docs_indexed = {
          nvf = "https://notashelf.github.io/nvf/options.html";
        };
      };
    };
  };

  nmt.script = ''
    assertFileExists home-files/.config/nix-search-tv/config.json
    assertFileContent home-files/.config/nix-search-tv/config.json \
      ${pkgs.writeText "settings-expected" ''
        {
          "experimental": {
            "render_docs_indexed": {
              "nvf": "https://notashelf.github.io/nvf/options.html"
            }
          },
          "indexes": [
            "home-manager",
            "nixos",
            "nixpkgs"
          ]
        }
      ''}
  '';
}
