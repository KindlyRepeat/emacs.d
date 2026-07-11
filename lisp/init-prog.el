(use-package cider
  :bind
  (:map cider-repl-mode-map
	(("M-r" . consult-history)))
  :hook
  (clojure-mode . cider-mode)
  :config
  (setq cider-prompt-for-symbol t
	cider-save-file-on-load t)

  (add-to-list 'display-buffer-alist
	       '("\\*cider-\\(doc\\|apropos\\|clojuredocs\\)"
		 (display-buffer-in-side-window)
		 (side . top)
		 (window-height . 0.35)
		 (dedicated . t)
		 (slot . 1)
		 (preserve-size . (t . t)))))

(use-package eglot
  :commands (eglot))

(use-package paredit
  :disabled t
  :hook
  ((clojurescript-mode . paredit-mode)
   (emacs-lisp-mode . paredit-mode))
  :config
  (unbind-key "M-s" paredit-mode-map))

(use-package pyvenv
  :disabled t				; TODO package for Guix
  :config
  (pyvenv-mode t)

  ;; Set correct Python interpreter
  (setq pyvenv-post-activate-hooks
        (list (lambda ()
                (setq python-shell-interpreter (concat pyvenv-virtual-env "bin/python3")))))
  (setq pyvenv-post-deactivate-hooks
        (list (lambda ()
                (setq python-shell-interpreter "python3")))))

(provide 'init-prog)
