;; -*- lexical-binding: t; -*-

(put 'narrow-to-region 'disabled nil)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("6945dadc749ac5cbd47012cad836f92aea9ebec9f504d32fe89a956260773ca4" "da75eceab6bea9298e04ce5b4b07349f8c02da305734f7c0c8c6af7b5eaa9738" "631c52620e2953e744f2b56d102eae503017047fb43d65ce028e88ef5846ea3b" "afa47084cb0beb684281f480aa84dab7c9170b084423c7f87ba755b15f6776ef" "a44e2d1636a0114c5e407a748841f6723ed442dc3a0ed086542dc71b92a87aee" "eb7cd622a0916358a6ef6305e661c6abfad4decb4a7c12e73d6df871b8a195f8" "bfc0b9c3de0382e452a878a1fb4726e1302bf9da20e69d6ec1cd1d5d82f61e3d" "dde643b0efb339c0de5645a2bc2e8b4176976d5298065b8e6ca45bc4ddf188b7" default))
 '(safe-local-variable-values
   '((org-use-fast-todo-selection)
     (org-todo-keywords
      (sequence "TODO" "FOO" "|" "DONE"))
     (eval progn
	   (require 'lisp-mode)
	   (defun emacs27-lisp-fill-paragraph
	       (&optional justify)
	     (interactive "P")
	     (or
	      (fill-comment-paragraph justify)
	      (let
		  ((paragraph-start
		    (concat paragraph-start "\\|\\s-*\\([(;\"]\\|\\s-:\\|`(\\|#'(\\)"))
		   (paragraph-separate
		    (concat paragraph-separate "\\|\\s-*\".*[,\\.]$"))
		   (fill-column
		    (if
			(and
			 (integerp emacs-lisp-docstring-fill-column)
			 (derived-mode-p 'emacs-lisp-mode))
			emacs-lisp-docstring-fill-column fill-column)))
		(fill-paragraph justify))
	      t))
	   (setq-local fill-paragraph-function #'emacs27-lisp-fill-paragraph))
     (geiser-repl-per-project-p . t)
     (eval with-eval-after-load 'yasnippet
	   (let
	       ((guix-yasnippets
		 (expand-file-name "etc/snippets/yas"
				   (locate-dominating-file default-directory ".dir-locals.el"))))
	     (unless
		 (member guix-yasnippets yas-snippet-dirs)
	       (add-to-list 'yas-snippet-dirs guix-yasnippets)
	       (yas-reload-all))))
     (eval setq-local guix-directory
	   (locate-dominating-file default-directory ".dir-locals.el"))
     (eval add-to-list 'completion-ignored-extensions ".go")
     (eval modify-syntax-entry 43 "'")
     (eval modify-syntax-entry 36 "'")
     (eval modify-syntax-entry 126 "'")
     (vc-prepare-patches-separately)
     (diff-add-log-use-relative-names . t)
     (vc-git-annotate-switches . "-w")
     (org-html-head-include-scripts nil)
     (org-html-stable-ids t)
     (org-html-head-include-default-style nil))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(provide 'safe-variables)
