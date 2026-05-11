{ lib, pkgs, ... }:
{
  programs.television.enable = true;

  programs.nix-search-tv.enable = true;

  nmt.script = ''
    assertFileExists home-files/.config/television/cable/nix-search-tv.toml
    assertFileContent home-files/.config/television/cable/nix-search-tv.toml \
      ${pkgs.writeText "settings-expected" ''
        [actions.homepage]
        command = "nix-search-tv homepage '{}' | xargs xdg-open"
        description = "Open link to homepage"
        mode = "execute"

        [actions.run]
        command = "nix run {replace:s/\\/ /#/g}"
        description = "Run the package"
        mode = "execute"

        [actions.shell]
        command = "nix shell {replace:s/\\/ /#/g}"
        description = "Enter new nix shell with this package"
        mode = "execute"

        [actions.source]
        command = "nix-search-tv source '{}' | xargs xdg-open"
        description = "Open link to source code"
        mode = "execute"

        [keybindings]
        ctrl-i = "actions:shell"
        ctrl-o = "actions:homepage"
        ctrl-r = "actions:run"
        ctrl-s = "actions:source"

        [metadata]
        description = "Search nix options and packages"
        name = "nix-search-tv"

        [preview]
        command = "${lib.getExe pkgs.nix-search-tv} preview \"{}\""

        [source]
        command = "${lib.getExe pkgs.nix-search-tv} print"
      ''}
  '';
}
