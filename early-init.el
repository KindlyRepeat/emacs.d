(defconst emacs-start-time (current-time))

(setq message-log-max 16384)

;; Increase garbarge collection for init.
(setq gc-cons-threshold 402653184)
(setq gc-cons-percentage 0.6)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(setq auto-window-vscroll nil
      inhibit-startup-screen t)

;; Package-initialize occurs automatically before use-init-file, but after early-init-file
(setq package-enable-at-startup nil)

;; Disable file name handler
(setq default-file-name-handler-alist file-name-handler-alist)
;;(setq file-name-handler-alist nil)

;; Re-enable file-name-handler-alist after initialization.
;; I moved this snippet here as it could supposedly fix the Invalid read syntax: "]" with helpful package.
;; (add-hook 'after-init-hook
;; 	  `(lambda ()
;; 	     (setq file-name-handler-alist default-file-name-handler-alist)))

(setq initial-frame-alist '((internal-border-width . 12) ;; left of line number, bottom of echo area and top of screen
			    (bottom-divider-width . 1)
			    (vertical-scroll-bars . nil)
			    (tool-bar-lines . 0)
			    (menu-bar-lines . 0)
			    (left-fringe . 4)
			    (right-fringe . 4)
			    (tab-bar-lines . 1))
      default-frame-alist initial-frame-alist)
