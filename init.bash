if [[ $(uname) == 'Darwin' ]]; then
    EMACS=/Applications/Emacs.app/Contents/MacOS/Emacs
    EMACSCLIENT=/Applications/Emacs.app/Contents/MacOS/bin/emacsclient
    alias emacs="$EMACS"
    alias emacsclient="$EMACSCLIENT"
else
    EMACS=emacs
    EMACSCLIENT=emacsclient
fi

edaemon(){
    rm -f ~/.emacs.desktop.lock ~/.emacs.d/.emacs.desktop.lock
    (cd ~ && "$EMACS" --daemon)
}

ec(){
    "$EMACSCLIENT" -c "$@" &
}

enw(){
    "$EMACSCLIENT" -nw "$@"
}

e(){
    # open file in an existing server process
    re='^[0-9]+$'
    if [[ $2 =~ $re ]]; then
	"$EMACSCLIENT" -n +$2:0 $1
    else
	"$EMACSCLIENT" -n "$@"
    fi
}
