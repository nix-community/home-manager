{ lib, pkgs, ... }:
{
  programs.television = {
    enable = true;
    extraPackages = [ ];
  };

  programs.nix-search-tv.enable = true;

  nmt.script =
    let
      keybinding_modifier = if pkgs.stdenv.isDarwin then "alt" else "ctrl";
      opener = if pkgs.stdenv.isDarwin then "open" else "xdg-open";
    in
    ''
      assertFileExists home-files/.config/television/cable/nix-search-tv.toml
      assertFileContent home-files/.config/television/cable/nix-search-tv.toml \
        ${pkgs.writeText "settings-expected" ''
          [actions.homepage]
          command = "${lib.getExe pkgs.nix-search-tv} homepage '{}' | xargs ${opener}"
          description = "Open link to homepage"
          mode = "execute"

          [actions.run]
          command = 'nix run {replace:s/\/ /#/g}'
          description = "Run the package"
          mode = "execute"

          [actions.shell]
          command = 'nix shell {replace:s/\/ /#/g}'
          description = "Enter new nix shell with this package"
          mode = "execute"

          [actions.source]
          command = "${lib.getExe pkgs.nix-search-tv} source '{}' | xargs ${opener}"
          description = "Open link to source code"
          mode = "execute"

          [keybindings]
          ${keybinding_modifier}-i = "actions:shell"
          ${keybinding_modifier}-o = "actions:homepage"
          ${keybinding_modifier}-r = "actions:run"
          ${keybinding_modifier}-s = "actions:source"

          [metadata]
          description = "Search nix options and packages"
          name = "nix-search-tv"

          [preview]
          command = '${lib.getExe pkgs.nix-search-tv} preview "{}"'

          [source]
          command = "${lib.getExe pkgs.nix-search-tv} print"
        ''}
    '';
}
