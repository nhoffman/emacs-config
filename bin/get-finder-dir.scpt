tell application "Finder"
    set finderWindow to window 1
    set currentDir to (POSIX path of (target of finderWindow as alias))
end tell
do shell script "echo " & quoted form of currentDir
