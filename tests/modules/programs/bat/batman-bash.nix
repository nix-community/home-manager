{ pkgs, ... }:
{
  programs = {
    bat = {
      enable = true;
      enableBashIntegration = true;
      extraPackages = [ pkgs.bat-extras.batman ];
    };
    bash = {
      enable = true;
      enableCompletion = false;
    };
  };

  nmt.script = ''
    assertFileExists home-files/.bashrc
    assertFileContains \
      home-files/.bashrc \
      'eval "$(@batman@/bin/batman --export-env)"'
  '';
}
