;;; early-init.el --- Early startup settings -*- lexical-binding: t; -*-

;; Let init.el bootstrap straight before explicitly activating package.el.
(setq package-enable-at-startup nil)

;; Apply before the initial GUI frame and to every daemon client frame.
(add-to-list 'default-frame-alist '(vertical-scroll-bars . nil))

;;; early-init.el ends here
