if (get_window_class() == "Gnome-terminal") then
    make_always_on_top();
end

if string.match(get_window_name(), "LibreOffice Writer") then
    maximize();
end

if (get_window_class()=="Org.gnome.Nautilus") then
   set_window_geometry(1600,300,900,700);
end
