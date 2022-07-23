if [[ $(uname) == 'Darwin' ]]; then
    if [[ $(uname -m) == 'arm64' ]]; then
        # assume we are using emacs-plus
        EMACS=/opt/homebrew/bin/emacs
        EMACS_BIN=/opt/homebrew/bin/emacsclient
    else
        EMACS=/Applications/Emacs.app/Contents/MacOS/Emacs
        EMACS_BIN=/Applications/Emacs.app/Contents/MacOS/bin
    fi
    alias emacs="$EMACS"
    # provides emacsclient
    export PATH=$EMACS_BIN:$PATH
else
    EMACS=$(readlink -f emacs)
fi

edaemon(){
    rm -f ~/.emacs.desktop.lock ~/.emacs.d/.emacs.desktop.lock
    (cd ~ && "$EMACS" --daemon)
}

ec(){
    emacsclient -c "$@" &
}

enw(){
    emacsclient -nw "$@"
}

e(){
    # open file in an existing server process
    re='^[0-9]+$'
    if [[ $2 =~ $re ]]; then
	emacsclient -n +$2:0 $1
    else
	emacsclient -n "$@"
    fi
}

ef () {
    if [[ -z $1 ]]; then
	echo "Use fzf to select file matching pattern and open in emacs"
	echo "usage: $0 find-pattern [grep-pattern]"
	return
    fi

    if [[ -z $2 ]]; then
	fname="$(fd -t file "$1" | fzf --exact)"
    else
	fname="$(fd -t file "$1" \
	    | xargs grep -l "$2" \
	    | fzf --exact --preview "grep --color=always -n -C 5 "$2" {}")"
    fi

    if [[ ! -z "$fname" ]]; then
	e "$fname"
    fi
}
