{ config, lib, pkgs, ... }:

with lib;

{
  config = {
    programs.blesh.enable = true;
    programs.bash.enable = true;
    programs.starship = {
      enable = true;
      enableBashIntegration = true;
    };

    nmt.script = ''
      assertFileRegex \
      home-files/.bashrc \
      $'^\[\[ \$- == \*i\* \]\] && source \'.*-blesh/share/ble.sh\' --noattach$'

      assertFileContains \
      home-files/.bashrc \
      '[[ ''${BLE_VERSION-} ]] && ble-attach'
    '';
  };
}
