{
  programs.bemenu = {
    enable = true;
    settings = {
      line-height = 28;
      prompt = "open";
      ignorecase = true;
      fb = "#1e1e2e";
      ff = "#cdd6f4";
      nb = "#1e1e2e";
      nf = "#cdd6f4";
      tb = "#1e1e2e";
      hb = "#1e1e2e";
      tf = "#f38ba8";
      hf = "#f9e2af";
      af = "#cdd6f4";
      ab = "#1e1e2e";
      width-factor = 0.3;
    };
  };

  test.stubs.bemenu = { };

  nmt.script = ''
    assertFileExists home-path/etc/profile.d/hm-session-vars.sh
    assertFileContains home-path/etc/profile.d/hm-session-vars.sh \
      "export BEMENU_OPTS=\"'--ab' '#1e1e2e' '--af' '#cdd6f4' '--fb' '#1e1e2e' '--ff' '#cdd6f4' '--hb' '#1e1e2e' '--hf' '#f9e2af' '--ignorecase' '--line-height' '28' '--nb' '#1e1e2e' '--nf' '#cdd6f4' '--prompt' 'open' '--tb' '#1e1e2e' '--tf' '#f38ba8' '--width-factor' '0.300000'\""
  '';
}
