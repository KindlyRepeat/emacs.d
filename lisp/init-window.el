;; -*- lexical-binding: t; -*-

;;; init-window.el --- Window management configuration

;;; Commentary: It might be useful to take a look at `split-window-sensibly' and `window-splittable-p'
;;

;;; Code:

(setq display-buffer-alist
	'(("\\*eshell\\*"
	   (display-buffer-in-side-window)
	   (side . bottom)
	   (window-height . 0.35)
	   (dedicated . t)
	   (preserve-size t . t))
	  ("\\*Help\\*\\\|*helpful.*\*"
	   (display-buffer-reuse-mode-window)
	   (window-width . 70)
	   (window-height . shrink-window-if-larger-than-buffer)
	   (mode . (help-mode helpful-mode)))
	  ("\\*Embark Collect:.*"
	   (display-buffer-in-side-window)
	   (side . left)
	   (window-height . 35)
	   (dedicated . t)
	   (slot . 1)
	   (preserve-size t . t))
	  ("\\*Man.*\\*"
	   (display-buffer-reuse-mode-window)
	   (window-width . 80)
	   (body-function . select-window))))

(use-package golden-ratio
  :disabled t
  :config
  (setq golden-ratio-auto-scale t))

(use-package window
  :bind
  (("C-x |" . od/split-window-dwim)
   ("C-x 1" . nol/delete-other-windows))
  :init
  (defun nol/delete-other-windows ()
    "Behaves like `delete-other-windows', but records the window configuration
 so `winner.el' can restore it."
    (interactive)
    (require 'winner)
    (winner-save-unconditionally)
    (delete-other-windows))

  :config
  ;; TODO : fix this. See `split-window-sensibly'. I had to decrease it from 160 to 120 otherwise it would split vertically.
  (setq split-width-threshold 120)
  ;; Increase this ratio to make splitting vertically easier
  (setq fit-window-to-buffer-horizontally t
	od/split-ratio 1.75)

  (defun od/split-horizontal-p (window ratio)
    "Return `t' when the ratio width / height is greater than a given ratio. 1.25 works great so far."
    (> (/ (float (window-pixel-width))
	  (window-pixel-height))
       ratio))

  (defun od/split-window-dwim ()
    "Split a window according according to its height/width."
    (interactive)
    (if (od/split-horizontal-p (selected-window) od/split-ratio)
	(split-window-horizontally)
      (split-window-vertically))
    (other-window 1)))

(use-package winner
  :bind
  (("C-s-p" . winner-undo)
   ("C-s-n" . winner-redo)
   ("C-c <right>" . winner-undo)
   ("C-c <left>" . winner-redo))
  :config
  ;; record window configuration
  (winner-mode 1))

(provide 'init-window)

;;; init-window.el ends here
