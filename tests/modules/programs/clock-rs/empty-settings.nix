{
  config = {
    programs.clock-rs.enable = true;

    tests.stubs.clock-rs = { };

    nmt.script = ''
      assertPathNotExists home-files/.config/clock-rs/conf.toml
    '';
  };
}
