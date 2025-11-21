{
  config,
  ...
}:

{
  config = {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      includes = [
        "config.d/*"
        "other/dir"
      ];
    };

    nmt.script = ''
      assertFileExists home-files/.ssh/config
      assertFileContains home-files/.ssh/config "Include config.d/* other/dir"
    '';
  };
}
