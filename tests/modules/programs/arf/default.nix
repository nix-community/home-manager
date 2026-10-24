{
  arf-settings = { config, ... }: {
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
      assertFileContent "home-files/.config/arf/arf.toml" ${./expected.toml}
    '';
  };
}
