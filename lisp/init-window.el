;;; init-window.el --- Window management configuration

;;; Commentary: It might be useful to take a look at `split-window-sensibly' and `window-splittable-p'
;;

;;; Code:

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

  (defun nol/display-buffer-pop-up-top-right (buffer alist)
    "Display BUFFER according to custom window splitting logic.

- If only one window: Split and display BUFFER in the new window.
- If two windows side by side: Split the right window horizontally, display BUFFER in the new top window.
- If two windows stacked: Split the top window vertically, display BUFFER in the new right window.
- Otherwise: Fallback to `display-buffer-use-some-window`."
    (let* ((windows (window-list))
           (n (length windows)))
      (cond
       ;; Only one window
       ((= n 1)
	(let ((newwin (split-window (selected-window) nil
                                    ;; Prefer vertical split if possible
                                    (if (> (window-width) (* 2 (window-height))) 'right 'below))))
          (window--display-buffer buffer newwin 'window alist)))

       ;; Exactly two windows: check arrangement
       ((= n 2)
	(let* ((win1 (nth 0 windows))
               (win2 (nth 1 windows))
               (edges1 (window-edges win1))
               (edges2 (window-edges win2)))
          (if (= (nth 1 edges1) (nth 1 edges2))
              ;; Side-by-side; choose the RIGHT window to split
              (let* ((right-win (if (> (nth 0 edges1) (nth 0 edges2)) win1 win2))
                     (newwin (split-window right-win nil 'below)))
		(window--display-buffer buffer right-win 'window alist))
            ;; Stacked; choose the TOP window to split
            (let* ((top-win (if (< (nth 1 edges1) (nth 1 edges2)) win1 win2))
                   (newwin (split-window top-win nil 'right)))
              (window--display-buffer buffer newwin 'window alist)))))

       ;; Fallback
       (t
	(display-buffer-use-some-window buffer alist)))))

  (setq display-buffer-alist
	'(("\\*eshell\\*"
	   (display-buffer-in-side-window)
	   (side . bottom)
	   (window-height . 0.35)
	   (dedicated . t)
	   (preserve-size t . t))
	;; (popper-display-control-p (popper-select-popup-at-bottom))
	  ("\\*Help\\*\\\|*helpful.*\*"
	   (display-buffer-reuse-mode-window
	    nol/display-buffer-pop-up-top-right)
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
	   (display-buffer-reuse-mode-window
	    nol/display-buffer-pop-up-top-right)
	   (body-function . select-window))))
	   ;; (lambda (buffer alist)
	   ;;   (let ((window (display-buffer-pop-up-window buffer alist))) (when window (select-window window)))))))

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
    (other-window 1))

  (defun od/display-buffer-in-side-window (buffer alist)
    "If the window is higher then it is wide, use a side window on the right. Otherwise use a side window on top. I lan to use this function to display help buffers at a consistent location. `window-height' and `window-width' must be set."
    (let ((position (if (> (frame-pixel-height) (frame-pixel-width))
			'top
		      'right)))
      (setf (alist-get 'side alist) position)
      ;; If both `window-height', `window-width' and `(preserve-size . (t . t))' are set, it will prevent the minibuffer from showing up.
      (if (eq position 'top)
	  (progn
	    (assq-delete-all 'window-width alist)
	    (setf (alist-get 'preserve-size alist) '(nil . t)))
	(progn
	  (assq-delete-all 'window-height alist)
	  (setf (alist-get 'preserve-size alist) '(t . nil)))))
    (display-buffer-in-side-window buffer alist))

  (defun od/toggle-maximize-buffer ()
    "Maximize current buffer"
    (interactive)
    (if (= 1 (length (window-list)))
	(jump-to-register '_)
      (progn
	(window-configuration-to-register '_)
	(delete-other-windows))))

  (defun od/nav-toggle-split-direction ()
    "Toggle window split from vertical to horizontal.
This work the other way around as well.
Credit: https://github.com/olivertaylor/dotfiles/blob/master/emacs/init.el"
    (interactive)
    (if (> (length (window-list)) 2)
	(error "Can't toggle with more than 2 windows")
      (let ((was-full-height (window-full-height-p)))
	(delete-other-windows)
	(if was-full-height
            (split-window-vertically)
          (split-window-horizontally))
	(save-selected-window
          (other-window 1)
          (switch-to-buffer (other-buffer)))))))

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
