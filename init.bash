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

ef () {
    if [[ -z $1 ]]; then
	echo "open file matching pattern in emacs"
	echo "usage $0 find-pattern [grep-pattern]"
	return
    fi

    if [[ -z $2 ]]; then
	fname="$(fd "$1" | fzf --exact)"
    else
	fname="$(fd "$1" \
	    | xargs grep -l "$2" \
	    | fzf --exact --preview "grep --color=always -n -C 5 "$2" {}")"
    fi

    if [[ ! -z "$fname" ]]; then
	e "$fname"
    fi
}
