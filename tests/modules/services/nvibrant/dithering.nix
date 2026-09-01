{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) getExe head;
  inherit (pkgs) writeShellScript;

  cfg = config.services.nvibrant;
  service = config.systemd.user.services.nvibrant;

  scriptFile = head service.Service.ExecStart;

  expectedFile = writeShellScript "apply-nvibrant" ''
    ATTRIBUTE=dithering ${getExe cfg.package} 1 2 2 0
  '';
in

{
  services.nvibrant = {
    enable = true;
    dithering = [
      true
      null
      false
      "auto"
    ];
  };

  nmt.script = ''
    local script_file=${scriptFile}
    local expected_file=${expectedFile}

    assertFileExists "$script_file"
    assertFileContent "$script_file" "$expected_file"
  '';
}
