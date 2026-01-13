{
  config = {
    programs.workstyle = {
      enable = true;
      settings = {
        alice = "A";
        bob = "B";
        other = {
          fallback_icon = "F";
          deduplicate_icons = false;
          separator = ": ";
        };
      };
    };

    nmt.script = ''
      assertFileExists home-files/.config/workstyle/config.toml
      assertFileContent home-files/.config/workstyle/config.toml ${./basic-configuration.toml}
    '';
  };
}
