{
  goldenFile,
  opacity ? "0.750000",
  showIntro ? "false",
}:

''
  serviceFile=home-files/.config/systemd/user/gromit-mpx.service

  assertFileExists $serviceFile
  assertFileRegex $serviceFile 'X-Restart-Triggers=.*gromitmpx\.cfg'
  assertFileRegex $serviceFile 'X-Restart-Triggers=.*gromitmpx\.ini'
  assertFileRegex $serviceFile 'ExecStart=.*/bin/gromit-mpx'

  assertFileExists home-files/.config/gromit-mpx.ini
  assertFileContent home-files/.config/gromit-mpx.ini ${builtins.toFile "gromit-mpx.ini" ''
    [Drawing]
    Opacity=${opacity}

    [General]
    ShowIntroOnStartup=${showIntro}
  ''}
  assertFileExists home-files/.config/gromit-mpx.cfg
  assertFileContent home-files/.config/gromit-mpx.cfg ${goldenFile}
''
