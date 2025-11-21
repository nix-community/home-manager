function lg
    set -x LAZYGIT_NEW_DIR_FILE ~/.lazygit/newdir
    command lazygit $argv
    if test -f $LAZYGIT_NEW_DIR_FILE
        cd (cat $LAZYGIT_NEW_DIR_FILE)
        rm -f $LAZYGIT_NEW_DIR_FILE
    end
end
