{
  config = {
    programs.discocss = {
      enable = true;
      discordAlias = false;
    };

    nmt.script = ''
      assertPathNotExists home-files/.config/discocss/custom.css
    '';
  };
}
