;; start emacs using
;; emacs -Q --load ~/.emacs.d/minimal/init.el

(setq user-init-file (or load-file-name (buffer-file-name)))
(setq user-emacs-directory (file-name-directory user-init-file))
(setq package-user-dir (concat (file-name-as-directory user-emacs-directory) "elpa"))

;; save customizations here instead of init.el
(setq custom-file (concat (file-name-as-directory user-emacs-directory) "custom.el"))
(unless (file-exists-p custom-file)
  (write-region "" nil custom-file))
(load custom-file)

(require 'package)
(setq package-archives
      '(("ELPA" . "https://tromey.com/elpa/")
        ("gnu" . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")
        ("melpa-stable" . "https://stable.melpa.org/packages/")))
(setq package-native-compile t)
(package-initialize)

(unless (package-installed-p 'use-package)
  (if (y-or-n-p "use-package is not installed yet - install it? ")
      (progn
        (message "** installing use-package")
        (package-refresh-contents)
        (package-install 'use-package))))

