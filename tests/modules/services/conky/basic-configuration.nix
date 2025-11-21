{
  services.conky = {
    enable = true;
    extraConfig = ''
      conky.text = [[
        S Y S T E M    I N F O
        $hr
        Host:$alignr $nodename
        Uptime:$alignr $uptime
        RAM:$alignr $mem/$memmax
      ]]
    '';
  };

  nmt.script = ''
    serviceFile="$TESTED/home-files/.config/systemd/user/conky.service"

    assertFileExists $serviceFile
    assertFileRegex "$serviceFile" \
        'ExecStart=@conky@/bin/conky --config .*conky.conf'

    configFile="$(grep -o '/nix.*conky.conf' "$serviceFile")"
    assertFileContent "$configFile" \
        ${./basic-configuration.conf}
  '';
}
