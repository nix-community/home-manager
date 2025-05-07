{
  config = {
    programs.man = {
      enable = true;
      generateCaches = true;
    };

    nmt.script = ''
      if [[ ! -f "$TESTED/home-path/share/man/index.bt" ]]; then
          fail "Expected man cache files to exist but they were not found."
      fi
    '';
  };
}
