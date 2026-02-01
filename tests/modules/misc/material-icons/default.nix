{
  material-icons =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      launcherGitPath = "symbols/web/action_key/materialsymbolssharp/action_key_fill1_40px.svg";
      disclosureTriangleGitPath = "symbols/web/arrow_right/materialsymbolssharp/arrow_right_24px.svg";
    in
    {
      config = {
        misc.material-icons = {
          enable = true;
          icons = {
            "disclosure-triangle.svg" = disclosureTriangleGitPath;
            "launcher.svg" = launcherGitPath;
            "launcher-white.svg" = {
              path = launcherGitPath;
              color = "white";
            };
          };

          groups = {
            test-theme = {
              color = "black";
              icons = {
                "launcher-black.svg" = launcherGitPath;
                "disclosure-triangle-black.svg" = disclosureTriangleGitPath;
              };
            };
          };
          hash = "sha256-Aelq8eAw/cmbTB+j+QDM8XN1qap6aR2UeXuxktuK/rI=";
        };

        home.file."icon-path-check".text = config.misc.material-icons.absolutePath "launcher.svg";

        nmt.script = ''
          assertFileExists home-path/share/icons/material/launcher.svg
          assertFileExists home-path/share/icons/material/launcher-white.svg
          assertFileExists home-path/share/icons/material/launcher-black.svg
          assertFileExists home-path/share/icons/material/disclosure-triangle.svg
          assertFileExists home-path/share/icons/material/disclosure-triangle-black.svg

          assertFileRegex home-path/share/icons/material/launcher-white.svg '^<svg fill="white" '
          assertFileContent home-path/share/icons/material/disclosure-triangle.svg ${pkgs.writeText "expected-disclosure-triangle-raw.svg" ''<svg xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 -960 960 960" width="24"><path d="M400-280v-400l200 200-200 200Z"/></svg>''}
          assertFileContent home-path/share/icons/material/disclosure-triangle-black.svg ${pkgs.writeText "expected-disclosure-triangle-black.svg" ''<svg fill="black" xmlns="http://www.w3.org/2000/svg" height="24" viewBox="0 -960 960 960" width="24"><path d="M400-280v-400l200 200-200 200Z"/></svg>''}

          assertFileContent home-files/icon-path-check ${pkgs.writeText "expected-icon-path" "${config.misc.material-icons.package}/share/icons/material/launcher.svg"}
        '';
      };
    };
}
