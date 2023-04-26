;;* dependencies
;; provides string-trim
(eval-when-compile (require 'subr-x))

;;* file and path utilities
(defvar nh/icloud
  "/Users/nhoffman/Library/Mobile Documents/com~apple~CloudDocs/Documents/sync"
  "Base directory for files stored in icloud")

(defun nh/path-join (&rest x)
  "Join elements of x with a path separator and apply `expand-file-name'"
  (expand-file-name
   (concat
    (mapconcat 'file-name-as-directory (seq-take x (- (length x) 1)) "")
    (elt x (- (length x) 1)))))

(defun nh/emacs-dir-path (name)
  "Return absolute path to a file in the same directory as `user-init-file'"
  (expand-file-name name user-emacs-directory))

(defun nh/safename (str)
  "Remove non-alphanum characters and downcase"
  (let ((exprs '(("^\\W+" "") ("\\W+$" "") ("\\W+" "-"))))
    (dolist (e exprs)
      (setq str (replace-regexp-in-string (nth 0 e) (nth 1 e) str)))
    (downcase str)))

;;* Package management
(require 'package)
(setq package-archives
      '(("ELPA" . "https://tromey.com/elpa/")
        ("gnu" . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")
        ("melpa-stable" . "https://stable.melpa.org/packages/")))

(setq package-archive-priorities
      '(("melpa-stable" . 20)
        ("gnu" . 10)
        ("melpa" . 5)))

(setq package-native-compile t)
(setq package-menu-hide-low-priority t)
(setq package-check-signature nil) ;; TODO: fix this properly
(package-initialize)

;; bootstrap use-package
(unless (package-installed-p 'use-package)
  (if (yes-or-no-p "use-package is not installed yet - install it? ")
      (progn
        (message "** installing use-package")
        (package-refresh-contents)
        (package-install 'use-package))
    (message "** defining fake use-package macro")
    (defmacro use-package (pkg &rest args)
      (warn
       "use-package is not installed - could not activate %s" (symbol-name pkg)))))

;; save customizations here instead of init.el
(setq custom-file (nh/emacs-dir-path "custom.el"))
(unless (file-exists-p custom-file)
  (write-region "" nil custom-file))
(load custom-file)

;;* startup and shutdown
(defun nh/set-default-font-verbosely (font-name)
  (interactive)
  (message (format "** setting default font to %s" font-name))
  (condition-case nil
      ;; (set-default-font font-name)
      (set-face-attribute 'default nil :font font-name)
    (error (message (format "** Error: could not set to font %s" font-name)))))

(defun nh/fix-frame (&optional frame)
  "Apply platform-specific settings."
  (interactive)
  (cond ((string= "ns" window-system) ;; cocoa
         (progn
           (message (format "** running %s windowing system" window-system))
           ;; key bindings for mac - see
           ;; http://stuff-things.net/2009/01/06/emacs-on-the-mac/
           ;; http://osx.iusethis.com/app/carbonemacspackage
           (set-keyboard-coding-system 'mac-roman)
           (setq mac-option-modifier 'meta)
           (setq mac-command-key-is-meta nil)
           (nh/set-default-font-verbosely "Menlo-15")))
        ((string= "x" window-system)
         (progn
           (message (format "** running %s windowing system" window-system))
           (set-default-font-verbosely "Liberation Mono-10")
           ;; M-w or C-w copies to system clipboard
           ;; see http://www.gnu.org/software/emacs/elisp/html_node/Window-System-Selections.html
           (setq x-select-enable-clipboard t)))
        (t
         (message "** running in terminal mode"))))
(nh/fix-frame)

(setq inhibit-splash-screen t)
(setq initial-scratch-message nil)
(setq require-final-newline t)
(setq delete-trailing-lines nil)
(add-hook 'before-save-hook 'delete-trailing-whitespace)
;; buffers opened from command line don't create new frame
(setq ns-pop-up-frames nil)

;; require prompt before exit on C-x C-c
(defun nh/ask-before-exit ()
  (interactive)
  (cond ((y-or-n-p "Quit? (save-buffers-kill-terminal) ")
	 (save-buffers-kill-terminal))))
(global-set-key (kbd "C-x C-c") 'nh/ask-before-exit)

;; kill buffer without asking which one by default
(global-set-key (kbd "C-x k") 'kill-this-buffer)

;;* desktop
(defun nh/desktop-save-no-p ()
  "Save desktop without prompting (replaces `desktop-save-in-desktop-dir')"
  (interactive)
  (desktop-save desktop-dirname))

(if (member "--no-desktop" command-line-args)
    (message "** desktop auto-save is disabled")
  (progn
    (message "** desktop auto-save is enabled")
    (require 'desktop)
    (desktop-save-mode 1)
    (add-hook 'auto-save-hook 'nh/desktop-save-no-p)))

;;* bookmarks
(defun nh/set-bookmark-for-function ()
  (interactive)
  (let* ((tag (read-string "project tag: "))
	 (funcname (which-function))
	 (name (format "%s %s" tag funcname)))
    (if (y-or-n-p (format "set bookmark '%s'? " name))
	(bookmark-set name))))

;;* appearance and GUI
(blink-cursor-mode 1)
(set-cursor-color "red")

(menu-bar-mode -1)   ;; hide menu bar
(scroll-bar-mode -1) ;; hide scroll bar
(tool-bar-mode -1)   ;; hide tool bar

(setq column-number-mode t)
(setq ediff-split-window-function 'split-window-horizontally)
;; prevent windows from being split vertically
(setq split-height-threshold nil)

;; File path in title bar.
(setq frame-title-format
      (list (format "%s %%S: %%j " (system-name))
            '(buffer-file-name "%f" (dired-directory dired-directory "%b"))))

;; show matching parens
(show-paren-mode 1)

(use-package rainbow-delimiters
  :ensure t)

;; use list-faces-display to show preview of all faces for the current theme
;; use M-x customize-group to modify theme elements in specific modes

(defvar nh/theme-dark 'spacemacs-dark)
(defvar nh/theme-light 'spacemacs-light)

(defun nh/hex-to-rgb (hexcolor)
  "Return a list of decimal RGB values from a hex color name"
  (mapcar (lambda (start)
            (string-to-number
             (substring-no-properties hexcolor start (+ start 2)) 16))
          '(1 3 5)))

(defun nh/toggle-theme ()
  "Toggle theme between preferred light and dark themes"
  (interactive)
  ;; sum the RGB values of the current theme's background color and guess that
  ;; the current theme is dark if < 300
  (if (< (apply '+ (nh/hex-to-rgb (face-attribute 'default :background))) 300)
      (load-theme nh/theme-light t)
    (load-theme nh/theme-dark t)))

(use-package spacemacs-theme
  :ensure t
  :defer t
  :init (load-theme nh/theme-dark t))

;;* execution environment
(defun nh/ssh-refresh ()
  "Reset the environment variable SSH_AUTH_SOCK"
  (interactive)
  (let
      ((ssh-auth-sock-old (getenv "SSH_AUTH_SOCK"))
       (mac-cmd "ls -t $(find /tmp/* -user $USER -name Listeners 2> /dev/null)")
       (linux-cmd "ls -t $(find /tmp/ssh-* -user $USER -name 'agent.*' 2> /dev/null)"))
    (setenv "SSH_AUTH_SOCK"
            (car (split-string
                  (shell-command-to-string
                   (if (eq system-type 'darwin) mac-cmd linux-cmd)))))
    (message
     (format "SSH_AUTH_SOCK %s --> %s"
             ssh-auth-sock-old (getenv "SSH_AUTH_SOCK")))))

(defun nh/prepend-path (path)
  "Add `path' to the beginning of $PATH unless already present."
  (interactive)
  (unless (string-match path (getenv "PATH"))
    (setenv "PATH" (concat path ":" (getenv "PATH")))))

(nh/prepend-path (nh/emacs-dir-path "bin"))
(add-to-list 'exec-path (nh/emacs-dir-path "bin"))

;;* other utility function

(defun nh/advice-unadvice (sym)
  "Remove all advices from symbol SYM."
  (interactive "aFunction symbol: ")
  (advice-mapc (lambda (advice _props) (advice-remove sym advice)) sym))

;; fix errors with connection to package repositories
;; see https://github.com/melpa/melpa/issues/7238
;; suppress on Ubuntu 18.04 to prevent errors
(unless
    (equal (string-trim (shell-command-to-string "lsb_release -rs")) "18.04")
  (setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3"))

;;* dired
;; use 'ls --dired' if available
(setq dired-use-ls-dired
      (if (eq (call-process-shell-command "ls --dired" nil nil nil) 0)
	  t nil))
;; dired performs file renaming using underlying version control system
(setq dired-vc-rename-file t)

;;* other settings
(put 'downcase-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'narrow-to-region 'disabled nil)

;; Default 'untabify converts a tab to equivalent number of spaces
;; before deleting a single character.
(setq backward-delete-char-untabify-method "all")
(setq-default indent-tabs-mode nil)

;; Let a period followed by a single space be treated as end of sentence
(setq sentence-end-double-space nil)
;; (setq-default fill-column 80)

(setq suggest-key-bindings 4)

(setq mouse-wheel-scroll-amount '(3 ((shift) . 3))) ;; number of lines at a time
(setq mouse-wheel-progressive-speed nil) ;; don't accelerate scrolling
(setq mouse-wheel-follow-mosue 't) ;; scroll window under mouse
(setq scroll-step 1) ;; keyboard scroll one line at a time
(setq scroll-conservatively 1) ;; scroll by one line to follow cursor off screen
(setq scroll-margin 2) ;; Start scrolling when 2 lines from top/bottom

(global-set-key (kbd "<f5>") 'call-last-kbd-macro)

;;* general utilities

(defun nh/back-window ()
  "switch windows with C- and arrow keys"
  (interactive)
  (other-window -1))
(global-set-key (kbd "C-<right>") 'other-window)
(global-set-key (kbd "C-<left>") 'nh/back-window)

(defun nh/insert-date ()
  "insert today's timestamp in format '<%Y-%m-%d %a>'"
  (interactive)
  (insert (format-time-string "<%Y-%m-%d %a>")))

(defun nh/copy-buffer-file-name ()
  "Add `buffer-file-name' to `kill-ring' and echo the value to
the minibuffer"
  (interactive)
  (if buffer-file-name
      (progn
	(kill-new buffer-file-name t)
	(message buffer-file-name))
    (message "no file associated with this buffer")))

(defun nh/move-line-up ()
  (interactive)
  (transpose-lines 1)
  (previous-line 2))
(global-set-key (kbd "M-<up>") 'nh/move-line-up)

(defun nh/move-line-down ()
  (interactive)
  (next-line 1)
  (transpose-lines 1)
  (previous-line 1))
(global-set-key (kbd "M-<down>") 'nh/move-line-down)

(defun nh/transpose-buffers (arg)
  "Transpose the buffers shown in two windows."
  (interactive "p")
  (let ((selector (if (>= arg 0) 'next-window 'previous-window)))
    (while (/= arg 0)
      (let ((this-win (window-buffer))
            (next-win (window-buffer (funcall selector))))
        (set-window-buffer (selected-window) next-win)
        (set-window-buffer (funcall selector) this-win)
        (select-window (funcall selector)))
      ;; (setq arg (if (plusp arg) (1- arg) (1+ arg)))
      (setq arg (if (>= arg 0) (1- arg) (1+ arg)))
      )))
(global-set-key (kbd "C-x 4") 'nh/transpose-buffers)

(defun nh/switch-buffers-between-frames ()
  "switch-buffers-between-frames switches the buffers between the two last frames"
  (interactive)
  (let ((this-frame-buffer nil)
	(other-frame-buffer nil))
    (setq this-frame-buffer (car (frame-parameter nil 'buffer-list)))
    (other-frame 1)
    (setq other-frame-buffer (car (frame-parameter nil 'buffer-list)))
    (switch-to-buffer this-frame-buffer)
    (other-frame 1)
    (switch-to-buffer other-frame-buffer)))
(global-set-key (kbd "C-x 5") 'nh/switch-buffers-between-frames)

(defun nh/toggle-frame-split ()
  "If the frame is split vertically, split it horizontally or vice versa.
Assumes that the frame is only split into two."
  (interactive)
  (unless (= (length (window-list)) 2) (error "Can only toggle a frame split in two"))
  (let ((split-vertically-p (window-combined-p)))
    (delete-window) ; closes current window
    (if split-vertically-p
        (split-window-horizontally)
      (split-window-vertically)) ; gives us a split with the other window twice
    (switch-to-buffer nil))) ; restore the original window in this part of the frame
(global-set-key (kbd "C-x 6") 'nh/toggle-frame-split)

(defun nh/unfill-paragraph ()
  (interactive)
  (let ((fill-column (point-max)))
    (fill-paragraph nil)))
(global-set-key (kbd "M-C-q") 'nh/unfill-paragraph)

(defun nh/copy-region-or-line-other-window ()
  "Copy selected text or current line to other window"
  (interactive)
  (progn (save-excursion
           (if (region-active-p)
               (copy-region-as-kill
                (region-beginning) (region-end))
             (copy-region-as-kill
              (line-beginning-position) (+ (line-end-position) 1)))
           (other-window 1)
           (yank))
         (other-window -1)))

;; copied from https://emacs.stackexchange.com/questions/54659/how-to-delete-surrounding-brackets/54679#54679
(defun nh/delete-surround-at-point--find-brackets (pos)
  "Return a pair of buffer positions for the opening & closing bracket positions.
Or nil when nothing is found."
  (save-excursion
    (goto-char pos)
    (when
        (or
         ;; Check if we're on the opening brace.
         (when
             ;; Note that the following check for opening brace
             ;; can be skipped, however it can cause the entire buffer
             ;; to be scanned for an opening brace causing noticeable lag.
             (and
              ;; Opening brace.
              (eq (syntax-class (syntax-after pos)) 4)
              ;; Not escaped.
              (= (logand (skip-syntax-backward "/\\") 1) 0))
           (forward-char 1)
           (if (and (ignore-errors (backward-up-list 1) t) (eq (point) pos))
               t
             ;; Restore location and fall through to the next check.
             (goto-char pos)
             nil))
         ;; Check if we're on the closing or final brace.
         (ignore-errors (backward-up-list 1) t))

      ;; Upon success, return the pair as a list.
      (list (point)
            (progn
              (forward-list)
              (1- (point)))))))

(defun nh/delete-surround-at-point ()
  (interactive)
  (let ((range (nh/delete-surround-at-point--find-brackets (point))))
    (unless range
      (user-error "No surrounding brackets"))
    (pcase-let ((`(,beg ,end) range))
      ;; For user message.
      (let ((lines (count-lines beg end))
            (beg-char (char-after beg))
            (end-char (char-after end)))

        (save-excursion
          (goto-char end)
          (delete-char 1)
          (goto-char beg)
          (delete-char 1))
        (message
         "Delete surrounding \"%c%c\"%s" beg-char end-char
         (if (> lines 1)
             (format " across %d lines" lines)
           ""))))))

;;* spelling
(defvar nh/enable-flyspell-p "enable flyspell in various modes")

;; use aspell if installed
(if (cond
     ((executable-find "aspell")
      (setq ispell-dictionary "en")
      (setq ispell-program-name "aspell")))
    (progn
      (message "** using %s for flyspell" ispell-program-name)
      (autoload 'flyspell-mode "flyspell" "On-the-fly spelling checker." t)
      (setq flyspell-issue-welcome-flag nil)
      (setq nh/enable-flyspell-p t))
  (setq nh/enable-flyspell-p nil)
  (message "** could not find hunspell or aspell"))

;;* init file utilities
;; TODO: refer to
(defun nh/init-file-edit ()
  "Edit `user-init-file'"
  (interactive)
  (find-file user-init-file))

(defun nh/init-file-header-occur ()
  (interactive)
  (find-file user-init-file)
  (occur "^;;\\* "))

(defun nh/init-file-use-package-occur ()
  (interactive)
  (find-file user-init-file)
  (occur "^(use-package"))

(defun nh/init-file-header-insert ()
  "insert ';;*' header"
  (interactive)
  (insert ";;*"))

(defun nh/init-file-load ()
  "Reload init file"
  (interactive)
  (load user-init-file))

;;* saving
(setq make-backup-files nil)
(global-auto-revert-mode t)
(unless (< emacs-major-version 27)
  (setq auto-revert-avoid-polling t))

;; save buffers automatically
(use-package super-save
  :ensure t
  :config
  (super-save-mode +1))

(setq undo-limit 800000)
(setq undo-strong-limit 12000000)
(setq undo-outer-limit 120000000)

;; persistent undo history
(use-package undohist
  :ensure t
  :config
  (setq undohist-ignored-files '("COMMIT_EDITMSG"))
  (undohist-initialize))

;;* search and navigation (vertico, consult)

(use-package vertico
  :ensure t
  :init
  (vertico-mode)
  ;; Different scroll margin
  ;; (setq vertico-scroll-margin 0)

  ;; Show more candidates
  (setq vertico-count 20)

  ;; Grow and shrink the Vertico minibuffer
  (setq vertico-resize t)

  ;; Optionally enable cycling for `vertico-next' and `vertico-previous'.
  ;; (setq vertico-cycle t)
  )

(use-package orderless
  :ensure t
  :init
  ;; Configure a custom style dispatcher (see the Consult wiki)
  ;; (setq orderless-style-dispatchers '(+orderless-dispatch)
  ;;       orderless-component-separator #'orderless-escapable-split-on-space)
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion))))
  )

(use-package consult
  :ensure t
  ;; Replace bindings. Lazily loaded due by `use-package'.
  :bind (
         ;; replacements for default bindings
         ;; ("C-s" . consult-line) ;; swiper is better
         ("C-x b" . consult-buffer)
         ("M-g M-g" . consult-goto-line)
         ("M-g g" . consult-goto-line)
         ("M-y" . consult-yank-pop)

         ;; C-c bindings (mode-specific-map)
  ;;        ("C-c h" . consult-history)
  ;;        ("C-c m" . consult-mode-command)
  ;;        ("C-c k" . consult-kmacro)
  ;;        ;; C-x bindings (ctl-x-map)
  ;;        ("C-x M-:" . consult-complex-command)     ;; orig. repeat-complex-command
  ;;        ("C-x b" . consult-buffer)                ;; orig. switch-to-buffer
  ;;        ("C-x 4 b" . consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
  ;;        ("C-x 5 b" . consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
  ;;        ("C-x r b" . consult-bookmark)            ;; orig. bookmark-jump
  ;;        ("C-x p b" . consult-project-buffer)      ;; orig. project-switch-to-buffer
  ;;        ;; Custom M-# bindings for fast register access
  ;;        ("M-#" . consult-register-load)
  ;;        ("M-'" . consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
  ;;        ("C-M-#" . consult-register)
  ;;        ;; Other custom bindings
  ;;        ("M-y" . consult-yank-pop)                ;; orig. yank-pop
  ;;        ;; M-g bindings (goto-map)
  ;;        ("M-g e" . consult-compile-error)
  ;;        ("M-g f" . consult-flymake)               ;; Alternative: consult-flycheck
  ;;        ("M-g g" . consult-goto-line)             ;; orig. goto-line
  ;;        ("M-g M-g" . consult-goto-line)           ;; orig. goto-line
  ;;        ("M-g o" . consult-outline)               ;; Alternative: consult-org-heading
  ;;        ("M-g m" . consult-mark)
  ;;        ("M-g k" . consult-global-mark)
  ;;        ("M-g i" . consult-imenu)
  ;;        ("M-g I" . consult-imenu-multi)
  ;;        ;; M-s bindings (search-map)
  ;;        ("M-s d" . consult-find)
  ;;        ("M-s D" . consult-locate)
  ;;        ("M-s g" . consult-grep)
  ;;        ("M-s G" . consult-git-grep)
  ;;        ("M-s r" . consult-ripgrep)
  ;;        ("M-s l" . consult-line)
  ;;        ("C-s" . consult-line)
  ;;        ("M-s L" . consult-line-multi)
  ;;        ("M-s m" . consult-multi-occur)
  ;;        ("M-s k" . consult-keep-lines)
  ;;        ("M-s u" . consult-focus-lines)
  ;;        ;; Isearch integration
  ;;        ("M-s e" . consult-isearch-history)
  ;;        :map isearch-mode-map
  ;;        ("M-e" . consult-isearch-history)         ;; orig. isearch-edit-string
  ;;        ("M-s e" . consult-isearch-history)       ;; orig. isearch-edit-string
  ;;        ("M-s l" . consult-line)                  ;; needed by consult-line to detect isearch
  ;;        ("M-s L" . consult-line-multi)            ;; needed by consult-line to detect isearch
  ;;        ;; Minibuffer history
  ;;        :map minibuffer-local-map
  ;;        ("M-s" . consult-history)                 ;; orig. next-matching-history-element
  ;;        ("M-r" . consult-history)                ;; orig. previous-matching-history-element
  )
  ;; Enable automatic preview at point in the *Completions* buffer. This is
  ;; relevant when you use the default completion UI.
  :hook (completion-list-mode . consult-preview-at-point-mode)

  ;; The :init configuration is always executed (Not lazy)
  :init

  ;; Optionally configure the register formatting. This improves the register
  ;; preview for `consult-register', `consult-register-load',
  ;; `consult-register-store' and the Emacs built-ins.
  (setq register-preview-delay 0.5
        register-preview-function #'consult-register-format)

  ;; Optionally tweak the register preview window.
  ;; This adds thin lines, sorting and hides the mode line of the window.
  (advice-add #'register-preview :override #'consult-register-window)

  ;; Use Consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  :config

  ;; Optionally configure preview. The default value
  ;; is 'any, such that any key triggers the preview.
  ;; (setq consult-preview-key 'any)
  ;; (setq consult-preview-key (kbd "M-."))
  ;; (setq consult-preview-key (list (kbd "<S-down>") (kbd "<S-up>")))
  ;; For some commands and buffer sources it is useful to configure the
  ;; :preview-key on a per-command basis using the `consult-customize' macro.
  (consult-customize
   consult-theme :preview-key '(:debounce 0.2 any)
   consult-ripgrep consult-git-grep consult-grep
   consult-bookmark consult-recent-file consult-xref
   consult--source-bookmark consult--source-file-register
   consult--source-recent-file consult--source-project-recent-file
   ;; :preview-key (kbd "M-.")
   :preview-key '(:debounce 0.4 any))

  ;; Optionally configure the narrowing key.
  ;; Both < and C-+ work reasonably well.
  (setq consult-narrow-key "<") ;; (kbd "C-+")

  ;; Optionally make narrowing help available in the minibuffer.
  ;; You may want to use `embark-prefix-help-command' or which-key instead.
  ;; (define-key consult-narrow-map (vconcat consult-narrow-key "?") #'consult-narrow-help)

  ;; By default `consult-project-function' uses `project-root' from project.el.
  ;; Optionally configure a different project root function.
  ;; There are multiple reasonable alternatives to chose from.
  ;;;; 1. project.el (the default)
  ;; (setq consult-project-function #'consult--default-project--function)
  ;;;; 2. projectile.el (projectile-project-root)
  ;; (autoload 'projectile-project-root "projectile")
  ;; (setq consult-project-function (lambda (_) (projectile-project-root)))
  ;;;; 3. vc.el (vc-root-dir)
  ;; (setq consult-project-function (lambda (_) (vc-root-dir)))
  ;;;; 4. locate-dominating-file
  ;; (setq consult-project-function (lambda (_) (locate-dominating-file "." ".git")))
)

(use-package marginalia
  :ensure t
  ;; Either bind `marginalia-cycle' globally or only in the minibuffer
  :bind (("M-A" . marginalia-cycle)
         :map minibuffer-local-map
         ("M-A" . marginalia-cycle))
  :init (marginalia-mode))

;;* search and navigation (ivy, counsel, and friends)
;; (use-package ivy
;;   :ensure t
;;   :pin melpa
;;   :config
;;   (ivy-mode 1)
;;   (setq enable-recursive-minibuffers t)
;;   (setq ivy-count-format "%d/%d ")
;;   (setq ivy-height 30)
;;   (global-set-key (kbd "C-c C-r") 'ivy-resume))

;; (use-package counsel
;;   :ensure t
;;   :pin melpa
;;   :bind (("M-x" . counsel-M-x)
;;          ("C-x C-f" . counsel-find-file)
;;          ("C-c g" . counsel-git)
;;          ("C-c j" . counsel-git-grep)
;;          ("C-c a" . counsel-ag)
;;          ("M-y" . counsel-yank-pop))
;;   :config
;;   (define-key minibuffer-local-map (kbd "C-r") 'counsel-minibuffer-history))

(use-package swiper
  :ensure t
  :config
  (global-set-key (kbd "C-s") 'swiper))

(use-package projectile
  :ensure t
  :init
  ;; (setq projectile-completion-system 'ivy)
  :config
  (define-key projectile-mode-map (kbd "C-c p") 'projectile-command-map)
  (add-to-list 'projectile-globally-ignored-modes "fundamental-mode")
  (projectile-mode +1))

(use-package avy
  :ensure t
  :bind (("M-'" . avy-goto-word-1)
	 ("C-M-SPC" . avy-goto-char-timer)))

;; see https://github.com/ericdanan/counsel-projectile
;; (use-package counsel-projectile
;;   :ensure t
;;   :config
;;   (counsel-projectile-mode))

(use-package rg
  :ensure t
  :config
  (rg-enable-menu))

(when (boundp 'grep-find-ignored-directories)
  (add-to-list 'grep-find-ignored-directories ".eggs")
  (add-to-list 'grep-find-ignored-directories "src"))

;; (defun nh/grep-ignore-venv-current-project (&rest args)
;;   (interactive)
;;   (let ((venv (find-venv-current-project)))
;;     (if venv
;;         (progn
;;           (setq venv (file-name-nondirectory
;;                       (replace-regexp-in-string "/$" "" venv)))
;;           (message "adding '%s' to grep-find-ignored-directories" venv)
;;           (add-to-list 'grep-find-ignored-directories venv))
;;       (message "no virtualenv at this location")
;;       )))

;; (advice-add 'rgrep :before #'nh/grep-ignore-venv-current-project)
;; (advice-add 'projectile-grep :before #'nh/grep-ignore-venv-current-project)
;; (advice-add 'counsel-projectile-grep :before #'nh/grep-ignore-venv-current-project)

;;* auto-complete using company-mode
;; (use-package company
;;   :ensure t
;;   :defer t
;;   :config
;;   (setq company-minimum-prefix-length 1
;; 	company-idle-delay 0
;; 	company-tooltip-limit 10
;; 	company-transformers nil
;; 	company-show-numbers t)
;;   (global-company-mode)
;;   :hook (python-mode . company-mode))

;; * elgot
(use-package eglot
  :ensure t
  :defer t
  :config
  (setq eldoc-echo-area-use-multiline-p nil))

;;* elisp
(use-package paredit
  :ensure t
  :bind
  (:map paredit-mode-map
        ("C-<left>" . nh/back-window)
        ("C-<right>" . other-window)))

;;* python
(defcustom nh/py3-venv
  (nh/emacs-dir-path "py3-env") "virtualenv for flycheck, etc")

(defcustom nh/venv-setup-packages
  '("pip" "wheel" "'python-lsp-server[all]'" "autoflake")
  "packages to install using `nh/venv-setup'")

(defun nh/py3-venv-bin (name)
  "Return the path to an executable installed in `nh/py3-venv'"
  (nh/path-join nh/py3-venv "bin" name))

(use-package python-mode
  :preface
  (defun nh/python-shell-make-comint (orig-fun &rest args)
    "Fix issue where python code block evaluation freezes on a mac in
     org-mode using :session. This as a bug in prompt detection
     in python.el: apparently the startup message for the python
     interpreter is not being recognized. Launching the
     interpreter with python -q suppresses the prompt, but the
     variable python-shell-interpreter-args does not appear to be
     respected. So the brute force solution is to advise the
     function that sets up inferior-python-mode to add -q:"
    (setq args (append '("python3 -q") (cdr args)))
    (apply orig-fun args))
  (if (eq system-type 'darwin)
      (progn
        (advice-add 'python-shell-make-comint :around #'nh/python-shell-make-comint)
        (setq python-shell-completion-native-enable nil)))
  :mode
  ("\\.py$'" . python-mode)
  ("\\.wsgi$" . python-mode)
  ("\\.cgi$" . python-mode)
  ("SConstruct" . python-mode)
  ("SConscript" . python-mode)
  :config
  (setq python-shell-interpreter "python3")
  (setq tab-width 4)
  (setq python-indent-guess-indent-offset t)
  (setq python-indent-guess-indent-offset-verbose nil)
  (setq python-indent-offset tab-width)
  :hook
  (python-mode . (lambda ()
		   (setq display-fill-column-indicator-column 80))))

(use-package pyvenv
  :ensure t)

(defun nh/venv-list (basedir)
  "Return a list of paths to virtualenvs in 'basedir' or nil if
 none can be found"
  (interactive)
  (let ((fstr "find %s -path '*bin/activate' -maxdepth 5")
        (pth (replace-regexp-in-string "/$" "" basedir)))
    (mapcar (lambda (string)
              (replace-regexp-in-string "/bin/activate$" "" string))
            (cl-remove-if
             (lambda (string) (= (length string) 0))
             (split-string (shell-command-to-string (format fstr pth)) "\n")))
    ))

(defun nh/pylsp-installed-p ()
  (= 0 (shell-command "python -c 'import pylsp' 2>/dev/null")))

(defun nh/venv-activate-eglot ()
  "Activate eglot in the selected virtualenv, installing
dependencies if necessary."
  (interactive)
  (nh/venv-activate)
  (unless (nh/pylsp-installed-p)
    (save-excursion (nh/venv-setup)))
  (eglot-ensure))

(defun nh/venv-activate ()
  "Activate the virtualenv in the current project, or in
`default-directory' if not in a project. Prompts for a selection
if there is more than one option."
  (interactive)
  (let* ((thisdir (or (projectile-project-root) default-directory))
	 (venvs (append
                 (nh/venv-list thisdir)
                 (nh/venv-list (expand-file-name "~/.pyenv/versions"))
                 `(,nh/py3-venv)))
         ;; maybe use completing-read
	 (venv (completing-read "choose a virtualenv: " venvs)))
    (pyvenv-activate venv)
    (message "Activated virtualenv %s (%s)"
	     venv (string-trim (shell-command-to-string "python3 --version")))))

(defun nh/venv-setup ()
  "Install or update packages specified in `nh/venv-setup-packages'
to the active virtualenv. Prompts for a selection if no
virtualenv is active."
  (interactive)
  (unless pyvenv-virtual-env (nh/venv-activate))
  (let ((bufname nil)
	(packages (mapconcat 'identity nh/venv-setup-packages " ")))
    (if (nh/pylsp-installed-p)
        (message "dependencies already installed")
      (if (y-or-n-p (format "Install dependencies to %s?" pyvenv-virtual-env))
          (progn (setq bufname (generate-new-buffer
                                (format "*%s*" pyvenv-virtual-env)))
                 (if (= 0 (call-process-shell-command
	                       (format "%sbin/pip install -U %s"
                                       pyvenv-virtual-env packages)
	                       nil bufname t))
                     (message "installation complete, see output in %s" bufname)
                   (switch-to-buffer bufname)))))))

(defun nh/pip-install (package)
  "Pip install a python package in a virtualenv. Prompts for a
selection if no virtualenv is active."
  (interactive "sPackage name: ")
  (unless pyvenv-virtual-env (nh/venv-activate))
  (let ((bufname (generate-new-buffer (format "*%s*" pyvenv-virtual-env)))
        (command (format "%sbin/pip install -U %s"
                         pyvenv-virtual-env package)))
    (if (= 0 (call-process-shell-command command nil bufname t))
        (message "installation complete, see output in %s" bufname)
      (switch-to-buffer bufname))))

(use-package flycheck
  :ensure t
  :pin melpa
  :config
  (setq flycheck-flake8rc (nh/emacs-dir-path "flake8.conf"))
  (setq flycheck-pylintrc (nh/emacs-dir-path "python-pylint.conf"))
  :hook
  (python-mode . flycheck-mode))

(defun nh/python-flycheck-select-checker (checker)
  (interactive)
  (flycheck-reset-enabled-checker checker)
  (flycheck-disable-checker checker t)
  (flycheck-select-checker checker))

(defun nh/python-flycheck-select-checkers ()
  (interactive)
  (nh/venv-setup)
  (flycheck-mode t)
  ;; checkers are run in reverse order of activation in lines below
  (nh/python-flycheck-select-checker 'python-pylint)
  (nh/python-flycheck-select-checker 'python-flake8)
  ;; (flycheck-verify-setup)
  )

;; function to reformat using yapf
(defun nh/yapf-region-or-buffer ()
  "Apply yapf to the current region or buffer"
  (interactive)
  (let* ((yapf (nh/py3-venv-bin "yapf"))
	 (yapf-config (nh/emacs-dir-path "yapf.cfg"))
	 ;; use config file if exists
	 (yapf-cmd (if (file-exists-p yapf-config)
		       (concat yapf " --style " yapf-config)
		     yapf)))
    (unless (region-active-p)
      (mark-whole-buffer))
    (shell-command-on-region
     (region-beginning) (region-end)  ;; beginning and end of region or buffer
     yapf-cmd                         ;; command and parameters
     (current-buffer)                 ;; output buffer
     t                                ;; replace?
     "*yapf errors*"                  ;; name of the error buffer
     t)                               ;; show error buffer?
    ))

;; (defun nh/autopep8-and-ediff ()
;;   "Compare the current buffer to the output of autopep8 using ediff"
;;   (interactive)
;;   (let ((p8-output
;;          (get-buffer-create (format "* %s autopep8 *" (buffer-name)))))
;;     (shell-command-on-region
;;      (point-min) (point-max)    ;; beginning and end of buffer
;;      "autopep8 -"               ;; command and parameters
;;      p8-output                  ;; output buffer
;;      nil                        ;; replace?
;;      "*autopep8 errors*"        ;; name of the error buffer
;;      t)                         ;; show error buffer?
;;     (ediff-buffers (current-buffer) p8-output)))

;;* javascript/json
(use-package json-mode
  :ensure t)

(add-hook 'js-mode-hook
          (lambda ()
            (make-local-variable 'js-indent-level)
            (setq js-indent-level 2)))

(add-hook 'json-mode-hook
          (lambda ()
            (make-local-variable 'js-indent-level)
            (setq js-indent-level 2)))

;;* ESS (R language support)

(defun nh/set-inferior-ess-r-program-name ()
  "Set `inferior-ess-r-program-name' as the absolute path to the R
interpreter. On systems using 'modules'
(http://modules.sourceforge.net/), load the R module before defining
the path."
  (interactive)
  (setq inferior-ess-r-program-name
	(string-trim
	 (shell-command-to-string
	  "which ml > /dev/null && (ml R; which R) || which R"))))

(use-package ess
  :ensure t
  :pin melpa
  :defer t
  :config
  (setq ess-S-assign "_")
  (add-hook 'ess-mode-hook
            (lambda()
              (message "** Loading ess-mode hooks")
	          (ess-toggle-underscore nil)
              (ess-set-style 'GNU 'quiet)
	          (nh/set-inferior-ess-r-program-name))))

;; (use-package poly-R
;;   :ensure t)

(use-package markdown-mode
  :commands (markdown-mode gfm-mode)
  :mode (("README\\.md" . gfm-mode)
         ("\\.md" . markdown-mode)
         ("\\.markdown" . markdown-mode))
  :bind (:map markdown-mode-map
              ;; don't redefine =M-<left>= and =M-<right>= in this mode
              ("M-<right>" . nil)
              ("M-<left>" . nil))
  :init  (setq markdown-command "multimarkdown")
  :config
  ;; (set-face-background 'markdown-pre-face "grey20")
  ;; (set-face-background 'markdown-markup-face "grey20")
  ;; (set-face-background 'markdown-code-face "grey20")
  ;; (set-face-background 'markdown-inline-code-face "grey20")
  ;; (set-face-foreground 'markdown-markup-face "lavender")
  )

;; https://plantarum.ca/2021/10/03/emacs-tutorial-rmarkdown/
(use-package poly-markdown
  :ensure t
  :init (setq markdown-code-block-braces t)
  :mode (("\\.Rmd" . poly-gfm+r-mode)))

;;* org-mode
(use-package org
  :preface
  (defun nh/org-mode-hooks ()
    (visual-line-mode)
    (yas-minor-mode t))
  (defadvice org-todo-list-bottom (after nh/org-todo-list ())
    "Move to bottom of page after entering org-todo-list"
    (progn (end-of-buffer) (recenter-top-bottom)))
  (defadvice org-download-screenshot (before nh/org-download-screenshot-advice ())
    "Remove extra lines before inserted screenshot and check for pngpaste"
    (if (executable-find "pngpaste")
        (progn (delete-blank-lines) (org-delete-backward-char 1))
      (error "pngpaste is not installed")))
  :mode
  ("\\.org\\'" . org-mode)
  ("\\.org\\.txt\\'" . org-mode)
  :bind
  (:map org-mode-map
        ("M-<right>" . forward-word)
        ("M-<left>" . backward-word)
        ("M-S-<right>" . org-do-demote)
        ("M-S-<left>" . org-do-promote)
        ("C-c C-v" . verb-command-map))
  :config
  (setq org-agenda-files `(,nh/org-index))
  (setq org-confirm-babel-evaluate nil)
  (setq org-src-fontify-natively t)
  (setq org-edit-src-content-indentation 0)
  (setq org-adapt-indentation nil)  ;; headlines are flush left
  (setq org-babel-python-command "python3")
  (setq org-not-done-regexp "TODO|WAITING")
  (setq org-image-actual-width nil)
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((R . t)
     (latex . t)
     (python . t)
     (sql . t)
     (sqlite . t)
     (emacs-lisp . t)
     (dot . t)
     (verb . t)
     (shell . t)
     (mermaid . t)))
  ;; org-open-at-point uses system app for png
  (add-to-list 'org-file-apps '("\\.png\\'" . system))
  (ad-activate 'org-todo-list-bottom)
  (ad-activate 'org-download-screenshot)
  :hook
  (org-mode . nh/org-mode-hooks))

(defvar nh/org-index
  (concat (file-name-as-directory nh/icloud) "notes/index.org")
  "Path to primary org-mode notes file")

;; https://zzamboni.org/post/how-to-insert-screenshots-in-org-documents-on-macos/
;; requires pngpaste (install with homebrew)
(defvar nh/org-download-image-dir "images"
  "Directory name for storing images downloaded by `org-download'")

(defun nh/org-show-todos-move-down ()
  "Show TODOs in main notes file"
  (interactive)
  (find-file nh/org-index)
  (org-show-todo-tree nil)
  (end-of-buffer))

(defun nh/org-download-add-caption (link)
  "Annotate link with caption, enter RET for no output"
  (interactive)
  (let ((caption (read-string "Caption: ")))
    (if (> (length caption) 0) (format "#+CAPTION: %s" caption))))

(defun nh/org-open-org-download-dir ()
  (interactive)
  (let* ((buffer-file-dir (file-name-directory buffer-file-name))
         (image-dir (concat buffer-file-dir nh/org-download-image-dir)))
    (if (file-directory-p image-dir)
        (browse-url-of-file image-dir)
      (warn (format "Directory %s does not exist" image-dir)))))

;; https://emacs.stackexchange.com/questions/3981/how-to-copy-links-out-of-org-mode
(defun nh/org-link-at-point ()
  "Return absolute path of link at point"
  (let* ((link (org-element-lineage (org-element-context) '(link) t))
         (type (org-element-property :type link))
         (url (org-element-property :path link)))
    (if (equal type "file")
        (file-truename url)
      (error (format "%s is not a regular file" link)))))

(defun nh/org-link-file-delete ()
  "Remove link and delete the associated file"
  (interactive)
  (let ((link (nh/org-link-at-point)))
    (if (y-or-n-p (format "Delete %s?" link))
        (progn
          (delete-file link)
          (if (org-in-regexp org-link-bracket-re 1)
              (save-excursion
                (apply 'delete-region (list (match-beginning 0) (match-end 0)))
                ))))))

(defun nh/org-babel-tangle-block()
  "Tangle only the block at point"
  (interactive)
  (let ((current-prefix-arg '(4)))
    (call-interactively 'org-babel-tangle)))

(defun nh/org-add-entry (&optional filename time-format)
  "Add an entry to an org-file with today's timestamp."
  (interactive)
  (find-file (or filename buffer-file-name))
  (end-of-buffer)
  (delete-blank-lines)
  (insert (format-time-string (or time-format "\n* <%Y-%m-%d %a> "))))

(defun nh/org-add-entry-to-index ()
  (interactive)
  (nh/org-add-entry nh/org-index))

(defun nh/org-find-index ()
  (interactive)
  (find-file nh/org-index))

(defun nh/org-table-copy-cell ()
  "Copy org-table cell at point to the kill-ring."
  (interactive)
  (kill-new (string-trim (org-table-get-field)) t))

(defun nh/org-element-as-docx ()
  "Export the contents of the element at point to a file and
convert to .docx with pandoc"
  (interactive)
  (let* ((sec (car (cdr (org-element-at-point))))
         (header (plist-get sec ':title))
         (fname (nh/safename header))
         (basedir
          (shell-quote-argument
	   (read-directory-name
	    "Output directory: " (expand-file-name "~/Downloads"))))
         (orgfile (make-temp-file fname nil ".org"))
         (docx (concat (file-name-as-directory basedir) fname ".docx")))
    (write-region
     (plist-get sec ':begin) (plist-get sec ':end) orgfile)
    (call-process-shell-command (format "pandoc %s -o %s" orgfile docx))
    (if (y-or-n-p "open file?")
        (shell-command (format "open %s" docx)))
    (message "wrote %s" docx)
    ))

;;* org-mode helper packages
(use-package ox-minutes
  :ensure t
  :after (org))

(use-package org-re-reveal
  :ensure t
  :after (org))

(use-package verb
  :ensure t
  :pin melpa
  :after (org))

(use-package org-download
  :ensure t
  :after org
  :defer nil
  :custom
  (org-download-method 'directory)
  (org-download-image-dir nh/org-download-image-dir)
  (org-download-heading-lvl nil)
  (org-download-timestamp "%Y-%m-%d-%H%M%S_")
  (org-image-actual-width 600)
  (org-download-screenshot-method (format "%s %%s" (executable-find "pngpaste")))
  ;; (org-download-annotate-function 'nh/org-download-add-caption)
  (org-download-annotate-function (lambda (link) ""))
  :config
  (require 'org-download))

(use-package ob-mermaid
  :preface
  ;; ensure that images are displayed
  (nh/advice-unadvice 'org-babel-execute-src-block)
  (advice-add 'org-babel-execute-src-block :after
              (lambda (original-fun &optional rest)
                (org-display-inline-images nil t (point) (point-max))))
  :ensure t
  :after org)

;;* sh-mode

(add-to-list 'auto-mode-alist '("\\.zsh\\'" . sh-mode))
(add-to-list 'auto-mode-alist '("\\.bash\\'" . sh-mode))

(use-package flymake-shellcheck
  :ensure t
  :commands flymake-shellcheck-load
  :init
  (add-hook 'sh-mode-hook 'flymake-shellcheck-load))

;;* text-mode

(add-hook 'text-mode-hook
          (lambda ()
            ;; (longlines-mode)
            (if nh/enable-flyspell-p (flyspell-mode))))

;;* rst-mode
(add-hook 'rst-mode-hook
          (lambda ()
            (message "Loading rst-mode hooks")
            (if nh/enable-flyspell-p (flyspell-mode))
            (define-key rst-mode-map (kbd "C-c C-a") 'rst-adjust)))

;;* mermaid-mode

;; https://github.com/abrochard/mermaid-mode
;; available tags for dockerized mermaid cli:
;; https://github.com/mermaid-js/mermaid-cli/pkgs/container/mermaid-cli%2Fmermaid-cli/versions?filters%5Bversion_type%5D=tagged

(use-package mermaid-mode
  :ensure t
  :config
  (setq mermaid-mmdc-location "docker")
  (setq mermaid-flags
        (concat (format "run -u %s " (user-real-uid))
                "-v /tmp:/tmp "
                "ghcr.io/mermaid-js/mermaid-cli/mermaid-cli:latest")))

;;* tramp

(condition-case nil
    (require 'tramp)
  (setq tramp-default-method "scp")
  (error (message "** could not load tramp")))

;;* misc packages
(use-package yasnippet
  :ensure t
  :init
  (add-hook 'after-save-hook
            (lambda ()
              (when (eql major-mode 'snippet-mode)
                (yas-reload-all))))
  :config (yas-global-mode t)
  :mode ("\\.yasnippet" . snippet-mode))

(use-package magit
  :ensure t)

(use-package git-timemachine
  :ensure t)

(use-package smart-mode-line
  :ensure t
  :config
  (setq sml/no-confirm-load-theme t)
  (setq sml/theme 'light)
  (setq sml/name-width 30)
  (setq sml/time-format "%H:%M")
  (sml/setup))

(use-package tex-mode
  :ensure auctex)

(use-package groovy-mode
  :ensure t
  :pin melpa
  :mode ("\\.nf" . groovy-mode))

(use-package discover
  :ensure t
  :config
  (global-discover-mode 1))

;; shows list of options following prefix command
(use-package which-key
  :ensure t
  :config (which-key-mode))

(use-package yaml-mode
  :ensure t)

(use-package jinja2-mode
  :ensure t)

(use-package dockerfile-mode
  :ensure t
  :mode ("Dockerfile" . dockerfile-mode))

(use-package yagist
  :ensure t)

(use-package expand-region
  :ensure t
  :bind (("C-=" . er/expand-region)
	 ("C--" . er/contract-region)
	 ("C-M-." . hydra-expand-region/body)))

;;* OpenAI tools

(require 'netrc)
(defun nh/get-netrc-val (machine key)
  "Return the value corresponding to 'key' from ~/.netrc for a
specified machine.

eg (nh/get-netrc-val \"openai\" \"password\")"
  (let ((credentials (netrc-parse "~/.netrc")))
    (cdr (assoc key (netrc-machine credentials machine)))))

(defvar nh/onedrive
  (expand-file-name "~/Library/CloudStorage/OneDrive-UW"))

(defvar nh/gptel-chats
  (nh/path-join nh/onedrive "gptel-chats"))

(use-package gptel
  :ensure t
  :pin melpa
  :config
  (setq gptel-default-mode 'org-mode)
  :custom
  (gptel-api-key (nh/get-netrc-val "openai" "password"))
  (gptel-model "gpt-4"))

(defun nh/gptel-new-chat (title)
  (interactive "sTitle: ")
  (let* ((date (format-time-string "%Y-%m-%d"))
         (fname (format "%s-%s.org" date (nh/safename title)))
         (path (nh/path-join nh/gptel-chats fname)))
    (make-directory nh/gptel-chats t)
    (find-file path)
    (gptel-mode)
    (yas-expand-snippet (yas-lookup-snippet "gptel-preamble"))))

(defun nh/gptel-open-chat ()
  (interactive)
  (let ((chat (completing-read
               "select a chat: "
               (directory-files nh/gptel-chats nil ".org$"))))
    (find-file (nh/path-join nh/gptel-chats chat))
    (gptel-mode)))

;;* ielm
;; ielm is an elisp REPL. Open a new repl with "M-x ielm"

;; adapted from https://www.n16f.net/blog/making-ielm-more-comfortable/
(use-package ielm
  :preface
  (defun nh/ielm-init-history ()
    (let ((path (expand-file-name "ielm/history" user-emacs-directory)))
      (make-directory (file-name-directory path) t)
      (setq-local comint-input-ring-file-name path))
    (setq-local comint-input-ring-size 10000)
    (setq-local comint-input-ignoredups t)
    (comint-read-input-ring))

  (defun nh/ielm-write-history (&rest _args)
    (with-file-modes #o600
      (comint-write-input-ring)))
  :config
  (advice-add 'ielm-send-input :after 'nh/ielm-write-history)
  :hook
  (ielm-mode . eldoc-mode)
  (ielm-mode . nh/ielm-init-history)
  :bind (("C-r" . consult-history)))

;;* hydra
(use-package hydra
  :ensure t
  :config
  (defhydra hydra-launcher (:color teal :columns 4 :post (redraw-display))
    "hydra-launcher"
    ("C-g" redraw-display "<quit>")
    ("RET" redraw-display "<quit>")
    ("b" hydra-bookmarks/body "hyrda for bookmarks")
    ("B" nh/copy-buffer-file-name "nh/copy-buffer-file-name")
    ("c" nh/toggle-theme "toggle light/dark mode")
    ("d" nh/insert-date "nh/insert-date")
    ("e" save-buffers-kill-emacs "save-buffers-kill-emacs")
    ("f" nh/fix-frame "fix-frame")
    ("g" hydra-toggle-mode/body "toggle mode")
    ("G" hydra-gptel/body "gptel")
    ("i" hydra-init-file/body "hydra for init file")
    ("j" consult-imenu "consult-imenu")
    ("l" hydra-org-links/body "hydra-org-links")
    ("|" display-fill-column-indicator-mode "display-fill-column-indicator-mode")
    ("n" nh/org-find-index "nh/org-find-index")
    ("N" nh/org-add-entry-to-index "nh/org-add-entry-to-index")
    ("m" magit-status "magit-status")
    ("o" hydra-org-navigation/body "hydra-org-navigation")
    ("O" nh/copy-region-or-line-other-window "copy-region-or-line-other-window")
    ("p" hydra-python/body "python menu")
    ("P" package-list-packages "package-list-packages")
    ("r" rg-menu "rg-menu")
    ("s" nh/ssh-refresh "ssh-refresh")
    ("t" nh/org-show-todos-move-down "org-todo-list")
    ("T" nh/transpose-buffers "transpose-buffers")
    ("u" untabify "untabify")
    ("w" hydra-web-mode/body "web-mode commands")
    ("y" hydra-yasnippet/body "yasnippet commands")
    ("(" hydra-paredit/body "paredit commands"))
  (global-set-key (kbd "C-\\") 'hydra-launcher/body)

  (defhydra hydra-init-file (:color blue :columns 4 :post (redraw-display))
    "hydra-init-file"
    ("RET" redraw-display "<quit>")
    ("C-g" redraw-display "<quit>")
    ("i" nh/init-file-edit "edit init file")
    ("l" nh/init-file-load "reload init file")
    ("h" nh/init-file-header-occur "occur headers")
    ("H" nh/init-file-header-insert "insert header")
    ("u" nh/init-file-use-package-occur "occur use-package declarations"))

  ;; https://www.gnu.org/software/emacs/manual/html_node/emacs/Bookmarks.html
  (defhydra hydra-bookmarks (:color blue :columns 4 :post (redraw-display))
    "hydra-bookmarks"
    ("RET" redraw-display "<quit>")
    ("C-g" redraw-display "<quit>")
    ("l" list-bookmarks "list bookmarks")
    ("j" bookmark-jump "jump to bookmark")
    ("s" bookmark-set "set bookmark")
    ("d" bookmark-delete "delete bookmark")
    ("f" nh/set-bookmark-for-function "bookmark this function"))

  (defhydra hydra-toggle-mode (:color blue :columns 4 :post (redraw-display))
    "hydra-toggle-mode"
    ("RET" redraw-display "<quit>")
    ;; ("c" csv-mode "csv-mode")
    ("e" emacs-lisp-mode "emacs-lisp-mode")
    ("h" html-mode "html-mode")
    ("g" groovy-mode "groovy-mode")
    ("j" jinja2-mode "jinja2-mode")
    ("k" markdown-mode "markdown-mode")
    ("l" lineum-mode "lineum-mode")
    ("m" moinmoin-mode "moinmoin-mode")
    ("o" org-mode "org-mode")
    ("p" python-mode "python-mode")
    ("P" paredit-mode "paredit-mode")
    ("r" R-mode "R-mode")
    ("s" sql-mode "sql-mode")
    ("S" sh-mode "sh-mode")
    ("t" text-mode "text-mode")
    ("v" visual-line-mode "visual-line-mode")
    ("w" web-mode "web-mode")
    ("y" yaml-mode "yaml-mode"))

  (defhydra hydra-org-navigation
    (:exit nil :foreign-keys warn :columns 4 :post (redraw-display))
    "hydra-org-navigation"
    ("RET" nil "<quit>")
    ("b" nh/org-babel-tangle-block "nh/org-babel-tangle-block" :color blue)
    ("c" nh/org-table-copy-cell "nh/org-table-copy-cell" :color blue)
    ("i" org-previous-item "org-previous-item")
    ("k" org-next-item "org-next-item")
    ("<right>" org-next-block "org-next-block")
    ("<left>" org-previous-block "org-previous-block")
    ("<down>" outline-next-visible-heading "outline-next-visible-heading")
    ("<up>" outline-previous-visible-heading "outline-previous-visible-heading")
    ("o" consult-outline "consult-outline" :color blue)
    ("t" nh/org-show-todos-move-down "show todos" :color blue)
    ("S-<down>" org-forward-paragraph "org-forward-paragraph")
    ("S-<up>" org-backward-paragraph "org-backward-paragraph")
    ("s" (org-insert-structure-template "src") "add src block" :color blue)
    ("w" nh/org-element-as-docx "nh/org-element-as-docx" :color blue)
    ("q" nil "<quit>"))

  (defhydra hydra-org-links
    (:exit t :foreign-keys warn :columns 4 :post (redraw-display))
    "hydra-org-links"
    ("RET" nil "<quit>")
    ("d" nh/org-open-org-download-dir "nh/org-open-org-download-dir")
    ("i" org-download-screenshot "insert screenshot from clipboard")
    ("t" org-toggle-inline-images "org-toggle-inline-images")
    ("n" nh/org-add-entry "nh/org-add-entry")
    ("o" org-open-at-point "org-open-at-point (also C-l C-o)")
    ("x" nh/org-link-file-delete "delete linked file"))

  (defhydra hydra-python (:color blue :columns 4 :post (redraw-display))
    "hydra-python"
    ("RET" redraw-display "<quit>")
    ("c" nh/python-flycheck-select-checkers "activate flycheck checkers")
    ("d" eldoc-doc-buffer "eldoc-doc-buffer")
    ("e" flycheck-list-errors "flycheck-list-errors")
    ("E" nh/venv-activate-eglot "activate eglot")
    ("f" flycheck-verify-setup "flycheck-verify-setup")
    ("i" nh/pip-install "pip install package")
    ;; ("j" (swiper "class\\|def\\b") "jump to function or class")
    ("j" consult-imenu "consult-imenu")
    ("n" flycheck-next-error "flycheck-next-error" :color red)
    ("p" flycheck-previous-error "flycheck-previous-error" :color red)
    ("P" python-mode "python-mode")
    ("r" eglot-rename "eglot-rename")
    ("v" nh/venv-activate "nh/venv-activate")
    ("x" eglot-shutdown "eglot-shutdown")
    ("V" nh/venv-setup "nh/venv-setup")
    ("y" nh/yapf-region-or-buffer "nh/yapf-region-or-buffer"))

  (defhydra hydra-yasnippet (:color blue :columns 4 :post (redraw-display))
    "hydra-yasnippet"
    ("RET" redraw-display "<quit>")
    ("i" yas-insert-snippet "yas-insert-snippet"))

  (defhydra hydra-expand-region (:color red :columns 1)
    "hydra-expand-region"
    ("." er/expand-region "er/expand-region")
    ("," er/contract-region "er/contract-region"))

  (defhydra hydra-paredit
    (:exit nil :foreign-keys warn :columns 4 :post (redraw-display))
    "hydra-paredit"
    ("RET" nil "<quit>")
    ("<right>" right-char "right-char")
    ("<left>" left-char "left-char")
    ("<down>" next-line "next-line")
    ("<up>" previous-line "previous-line")
    ("." paredit-forward-slurp-sexp "paredit-forward-slurp-sexp")
    ("," paredit-backward-slurp-sexp "paredit-backward-slurp-sexp")
    (">" paredit-forward-barf-sexp "paredit-forward-barf-sexp")
    ("<" paredit-backward-barf-sexp "paredit-backward-barf-sexp")
    ("C-/" undo "undo")
    ("q" nil "<quit>"))

  (defhydra hydra-gptel (:color blue :columns 4 :post (redraw-display))
    "hydra-gptel"
    ("RET" redraw-display "<quit>")
    ("d" (dired nh/gptel-chat-dir) "open chat dir")
    ("g" gptel "new gptel buffer")
    ("n" nh/gptel-new-chat "nh/gptel-new-chat")
    ("o" nh/gptel-open-chat "nh/gptel-open-chat"))

  ) ;; end hydra config
