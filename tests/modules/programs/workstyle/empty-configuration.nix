{
  config = {
    programs.workstyle = {
      enable = true;
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/workstyle/config.toml
    '';
  };
}
