{
  config = {
    programs.inori.enable = true;

    nmt.script = ''
      assertPathNotExists home-files/.config/inori/config.toml
    '';
  };
}
