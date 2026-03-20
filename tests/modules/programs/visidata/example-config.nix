{
  programs.visidata = {
    enable = true;
    visidatarc = ''
      options.min_memory_mb=100

      bindkey('0', 'go-leftmost')

      def median(values):
          L = sorted(values)
          return L[len(L)//2]

      vd.aggregator('median', median)
    '';
  };

  nmt.script = ''
    assertFileExists home-files/.visidatarc
    assertFileContent home-files/.visidatarc \
    ${./config}
  '';
}
