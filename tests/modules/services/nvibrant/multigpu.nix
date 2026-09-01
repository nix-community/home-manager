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
    NVIDIA_GPU=0 ATTRIBUTE=dithering ${getExe cfg.package} 1 2 2 0
    NVIDIA_GPU=1 ATTRIBUTE=dithering ${getExe cfg.package} 2
    NVIDIA_GPU=0 ${getExe cfg.package} -1024 0 1023
    NVIDIA_GPU=1 ${getExe cfg.package} 0
  '';
in

{
  services.nvibrant = {
    enable = true;
    dithering = [
      [
        true
        null
        false
        "auto"
      ]
      [ null ]
    ];
    vibrancy = [
      [
        "0%"
        null
        "200%"
      ]
      [ null ]
    ];
  };

  nmt.script = ''
    local script_file=${scriptFile}
    local expected_file=${expectedFile}

    assertFileExists "$script_file"
    assertFileContent "$script_file" "$expected_file"
  '';
}
