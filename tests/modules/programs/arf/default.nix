{
  arf-settings =
    { config, pkgs, ... }:
    let
      configDir = if pkgs.stdenv.hostPlatform.isDarwin then "Library/Application Support" else ".config";
    in
    {
      programs.arf = {
        enable = true;
        package = config.lib.test.mkStubPackage { };

        settings = {
          editor.auto_suggestions = "cwd";
          editor.key_map = {
            alt-a = " <- ";
            alt-p = " |>\n";
            alt-l = "\\(x) ";
          };
        };
      };

      nmt.script = ''
        assertFileContent "home-files/${configDir}/arf/arf.toml" ${./expected.toml}
      '';
    };
}
