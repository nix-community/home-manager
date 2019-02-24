golden_file:

''
  serviceFile=home-files/.config/systemd/user/gromit-mpx.service

  assertFileExists $serviceFile
  assertFileRegex $serviceFile 'X-Restart-Triggers=.*gromitmpx\.cfg'
  assertFileRegex $serviceFile 'X-Restart-Triggers=.*gromitmpx\.ini'
  assertFileRegex $serviceFile 'ExecStart=.*/bin/gromit-mpx'

  assertFileExists home-files/.config/gromit-mpx.ini
  assertFileExists home-files/.config/gromit-mpx.cfg
  assertFileContent home-files/.config/gromit-mpx.cfg ${golden_file}
''
