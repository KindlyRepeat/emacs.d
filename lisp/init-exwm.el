;; -*- lexical-binding: t; -*-

;; Test, does it work with a WM now? No it doesn't.
(require 'exwm)
(message "exwm: Test !")
;; ( ?\s-  exwm-input-prefix-keys)

;; (setq exwm-workspace-number 2)
(setq exwm-workspace-show-all-buffers t)
;; Allow switching buffers between workspaces
(setq exwm-layout-show-all-buffers t)

(use-package exwm-randr
  :after exwm
  :hook
  (exwm-randr-screen-change . nol/xrandr-set-display)
  :init
  (defun nol/xrandr-connected-display-list ()
    (split-string
     (shell-command-to-string
      "xrandr --query | grep ' connected' | awk '{ print $1 }'")))

  (defun nol/xrandr-set-display ()
    (pcase (nol/xrandr-connected-display-list)
      ('("eDP-1") (start-process-shell-command
		   "xrandr" nil "xrandr --output eDP-1 --primary"))
      ('("eDP-1" "DP-1-1" "DP-1-3")
       (start-process-shell-command
	"xrandr" nil "xrandr --output DP-1-3 --auto --output eDP-1 --off --output DP-1-1 --off"))))
  :config
  (exwm-randr-mode))

;; Make class name the buffer name
(add-hook 'exwm-update-class-hook
          (lambda ()
            (exwm-workspace-rename-buffer exwm-class-name)))
(add-hook 'exwm-update-title-hook
            (lambda ()
              (pcase exwm-class-name
                ("Firefox" (exwm-workspace-rename-buffer
			    (format "Firefox: %s"
				    (string-remove-suffix " — Nightly" exwm-title)))))))

(defun od/configure-window-by-class ()
  (interactive)
  (pcase exwm-class-name
    ("Emacs" (call-interactively #'exwm-input-toggle-keyboard))
    ("Pavucontrol" (exwm-floating-toggle-floating))
    ("Org.gnome.Nautilus" (exwm-floating-toggle-floating))))

(add-hook 'exwm-manage-finish-hook #'od/configure-window-by-class)

;; HERE !


;; It is necessary to set `default-directory' to a local directory. Otherwise, it will try to execute the
;; program on a remote host if the buffer is remote.
(defun od/volume-up ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "pulsemixer --change-volume +2")
    (when (fboundp 'awesome-tray-volume-refresh) (awesome-tray-volume-refresh))))

(defun od/volume-down ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "pulsemixer --change-volume -2")
    (when (fboundp 'awesome-tray-volume-refresh) (awesome-tray-volume-refresh))))

(defun od/volume-mute ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "pulsemixer --set-volume 0")
    (when (fboundp 'awesome-tray-volume-refresh) (awesome-tray-volume-refresh))))

(defun od/brightness-up ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightnessctl set +5% &>/dev/null")))

(defun od/brightness-up ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightnessctl set +5% &>/dev/null")))

(defun od/brightness-down ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightnessctl --min-value=1 set 5%- &>/dev/null")))

(defun od/brightness-up-monitor-1 ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightness-display-port-0 +")))

(defun od/brightness-down-monitor-1 ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightness-display-port-0 -")))

(defun od/brightness-up-monitor-2 ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightness-hdmi-0 +")))

(defun od/brightness-down-monitor-2 ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightness-hdmi-0 -")))

(defun od/exwm-layout-toggle-fullscreen (arg)
  "Make window ID fullscreen. If called with a prefix, unset it"
  (interactive "p")
  (if arg
      (exwm-layout-unset-fullscreen)
    (exwm-layout-set-fullscreen)))

;; Keybindings that are not under `exwm-input-prefix-keys but
;; needs to be available everywhere (even in exwm buffers)
(exwm-input-set-key (kbd "s-<backspace>") 'other-frame)
(exwm-input-set-key (kbd "s-b") 'consult-buffer)
;; should probably just remap switch-to-buffer-other-window)
(exwm-input-set-key (kbd "s-0") 'od/delete-window)
(exwm-input-set-key (kbd "s-1") 'nol/delete-other-windows)
(exwm-input-set-key (kbd "s-2") 'od/split-window-below)
(exwm-input-set-key (kbd "s-3") 'od/split-window-right)
(exwm-input-set-key (kbd "s-o") 'ace-window)
(exwm-input-set-key (kbd "s-B") 'ivy-switch-buffer-other-window)
(exwm-input-set-key (kbd "s-f") 'find-file)
(exwm-input-set-key (kbd "s-t") 'shell)
(exwm-input-set-key (kbd "s-T") 'shell-other-window)
(exwm-input-set-key (kbd "s-p") 'previous-buffer)
(exwm-input-set-key (kbd "s-n") 'next-buffer)
(exwm-input-set-key (kbd "s-q") 'window-toggle-side-windows)
(exwm-input-set-key (kbd "s-h") 'windmove-left)
(exwm-input-set-key (kbd "s-j") 'windmove-down)
(exwm-input-set-key (kbd "s-k") 'windmove-up)
(exwm-input-set-key (kbd "s-l") 'windmove-right)
(exwm-input-set-key (kbd "s-c") 'quick-calc)
;; (exwm-input-set-key (kbd "s-d") 'dired-sidebar-toggle-sidebar)
(exwm-input-set-key (kbd "s-&") 'helm-run-external-command)
(exwm-input-set-key (kbd "s-SPC") 'exwm-floating-toggle-floating)
(exwm-input-set-key (kbd "C-s-h") 'windmove-swap-states-left)
(exwm-input-set-key (kbd "C-s-j") 'windmove-swap-states-down)
(exwm-input-set-key (kbd "C-s-k") 'windmove-swap-states-up)
(exwm-input-set-key (kbd "C-s-l") 'windmove-swap-states-right)
(exwm-input-set-key (kbd "s-F") 'exwm-layout-toggle-fullscreen)
(exwm-input-set-key (kbd "C-M-v") 'scroll-other-window)
(exwm-input-set-key (kbd "s-q") 'nol/exwm-switch-to-last-firefox)
(when (require 'windower nil t)
  (exwm-input-set-key (kbd "s-H") 'windower-move-border-left)
  (exwm-input-set-key (kbd "s-J") 'windower-move-border-below)
  (exwm-input-set-key (kbd "s-K") 'windower-move-border-above)
  (exwm-input-set-key (kbd "s-L") 'windower-move-border-right))

;; prefix `s-e'
(add-to-list 'exwm-input-prefix-keys 8388709)
;; prefix `s-s'
(add-to-list 'exwm-input-prefix-keys 8388723)
;; prefix `s-y'
(add-to-list 'exwm-input-prefix-keys 8388729)
;; prefix `M-s' (otherwise it is grabbed by Firefox
(add-to-list 'exwm-input-prefix-keys 134217843)

;; Get the url from a Firefox buffer (assume URL in Title in used)
(defun od/get-url-from-firefox-title ()
  (interactive)
  (nth 0 (s-match "http[s]?://[^ ]*" exwm-title)))

;;; Rename buffer to window title. Trim the url part of Firefox url (assuming I'm using the URL in title
;;; Firefox extension)
(defun od/exwm-rename-buffer-to-title ()
  (if (string-match-p "Firefox.*" exwm-class-name)
      (exwm-workspace-rename-buffer (s-replace
				     (concat (od/get-url-from-firefox-title) " - ")
					       ""
					       exwm-title))
    (exwm-workspace-rename-buffer exwm-title)))

;; (add-hook 'exwm-update-title-hook 'od/exwm-rename-buffer-to-title)



;;(add-hook 'exwm-floating-setup-hook 'exwm-layout-hide-mode-line)
;;(add-hook 'exwm-floating-exit-hook 'exwm-layout-show-mode-line)

(add-hook 'exwm-manage-finish-hook
          (lambda ()
            (when (and exwm-class-name
		       (string-match-p "Firefox.*" exwm-class-name))
              (exwm-input-set-local-simulation-keys
	       `(([?\C-p] . [up])
		 ([?\C-n] . [down])
		 ([?\C-b] . [left])
		 ([?\C-f] . [right])
		 ([?\M-<] . [home])
		 ([?\M->] . [end])
		 ([?\C-v] . [next])
		 ([?\M-v] . [prior])
		 ([?\C-s] . [?\C-f])
		 ([?\M-p] . [M-left])
		 ([?\M-n] . [M-right])
		 ;; window close undo ?
		 ;; window private ?
		 ([?\M-w] . [?\C-c])
		 ([?\C-w] . [?\C-x])
		 ([?\C-y] . [?\C-v])
		 ([?\C-/] . [?\C-z])
		 ;; redo ? Can I do C-g C-/ ? I'll have to try
		 ;;([?\C-g ?\C-/] . exwm-firefox-core-redo)
		 ([?\M-f] . [C-right])
		 ([?\M-b] . [C-left])
		 ([?\C-g] . [escape])
		 ([?\C-a] . [home])
		 ([?\C-e] . [end])
		 ([M-backspace] . [C-backspace])
		 ([M-d] . [C-delete])
		 ([?\C-k] . [S-end delete]))))))

;; Use key-event if unsure
;; TODO Ajouter C-s-p, C-s-n, C-s-f
(setq exwm-input-global-keys
      `(([XF86AudioRaiseVolume] . od/volume-up)
        ([XF86AudioLowerVolume] . od/volume-down)
	([XF86AudioMute] . od/volume-mute)
	([XF86MonBrightnessUp] . od/brightness-up)
	([XF86MonBrightnessDown] . od/brightness-down)
        ([S-XF86MonBrightnessUp] . od/brightness-up-monitor-2)
        ([S-XF86MonBrightnessDown] . od/brightness-down-monitor-2)
        ([?\M-!] . shell-command)
        ([?\M-&] . async-shell-command)
        ([?\M-:] . eval-expression)
	;;(,(kbd "s-y") . od/browse-or-searx)
	(,(kbd "C-s-f") . counsel-tramp)
	(,(kbd "C-s-p") . winner-undo)
	(,(kbd "C-s-n") . winner-redo)))

;; Mmmh, thats interesting. Maybe to use with with C-u s-y ?
(defun exwm-browse-other-window ()
  (interactive)
  (split-window-right)
  (with-selected-window (next-window)
    (browse-url "http://google.com")
    (sleep-for 0.3)))

(setq exwm-manage-force-tiling nil)

(defun od/get-firefox-buffer-total ()
  "Return the total of Firefox buffers. Used to show this total in the status bar"
    (let ((i 0))
      (dolist (element (buffer-list) nil)
	(with-current-buffer element
	  (if (and exwm-class-name
		   (string-match "Firefox.*" exwm-class-name))
	      (progn
		(setq i (+ i 1))))))
      i))

(defun od/firefox-buffer-p (buf)
  "Return `t' if the buffer is a Firefox buffer"
  (with-current-buffer buf
    (and (eq major-mode 'exwm-mode)
	 (string-match-p "Firefox.*" exwm-class-name))))

(defun od/get-a-firefox-buffer ()
  "Return a Firefox buffer. Useful to activate a Firefox add-on programmatically."
  (seq-find '(lambda (buf)
	       (with-current-buffer buf
		 (and exwm-class-name
		      (string-match-p "Firefox.*" exwm-class-name))))
	    (buffer-list)))

(setq od/firefox-dark-background-shortcut 'f2)
(setq od/firefox-org-capture-shortcut 'f4)

(defun od/toggle-firefox-dark-background ()
  "Enable the `Dark Background and Light Text' Firefox add-on."
  (interactive)
  (let ((buf (od/get-a-firefox-buffer)))
    (save-window-excursion
      (with-selected-window
	  (get-buffer-window
	   (pop-to-buffer buf)
	   t)
	(exwm-input--fake-key od/firefox-dark-background-shortcut) nil))))

(defun nol/exwm-switch-to-last-firefox ()
  "If already in a Firefox buffer, go back to the previous buffer.
Otherwise, switch to the most recent EXWM Firefox buffer (not already shown)."
  (interactive)
  (if (and (boundp 'exwm-class-name)
           (string= exwm-class-name "Firefox"))
      (switch-to-buffer (other-buffer))
    (let ((target
           (seq-find
            (lambda (buf)
              (when (and (not (eq buf (current-buffer)))
                         (string= (buffer-local-value 'exwm-class-name buf) "Firefox"))
                buf))
            (buffer-list))))
      (cond
       ((null target)
        (user-error "No other EXWM Firefox buffer found"))
       ((get-buffer-window target t)
        (message "Firefox buffer %S is already visible"
                 (buffer-name target)))
       (t
        (switch-to-buffer target))))))

(defvar od/polybar-first-monitor-process nil)
(defvar od/polybar-second-monitor-process nil)

(defun od/kill-panel ()
  (interactive)
  (when od/polybar-first-monitor-process
    (ignore-errors
      (kill-process od/polybar-first-monitor-process)))
  (when od/polybar-second-monitor-process
    (ignore-errors
      (kill-process od/polybar-second-monitor-process)))
  (setq od/polybar-first-monitor-process nil)
  (setq od/polybar-second-monitor-process nil))

(defun od/start-panel-light ()
  (interactive)
  (od/kill-panel)
  (setq od/polybar-first-monitor-process (start-process-shell-command "polybar-light" nil "polybar light-first-monitor"))
  (setq od/polybar-second-monitor-process
	(start-process-shell-command "polybar-light-second-monitor" nil "polybar light-second-monitor")))

(defun od/start-panel-dark ()
  (interactive)
  (od/kill-panel)
  (setq od/polybar-first-monitor-process (start-process-shell-command "polybar-dark" nil "polybar dark-first-monitor"))
  (setq od/polybar-second-monitor-process
	(start-process-shell-command "polybar-dark-second-monitor" nil "polybar dark-second-monitor")))

(defvar nol/panel-process nil)

(defun nol/kill-panel ()
  (interactive)
  (when nol/panel-process
    (ignore-errors
      (kill-process nol/panel-process)))
  (setq nol/panel-process nil))

(defun nol/start-panel ()
  (interactive)
  (nol/kill-panel)
  (setq nol/panel-process (start-process-shell-command "polybar" nil "polybar --config=~/dotfiles/polybar/config.ini")))

(defun nol/start-nextcloud ()
  (interactive)
  (start-process-shell-command "nextcloud" nil "nextcloud"))

(defun exwm/run-in-background (command)
  (let ((command-parts (split-string command "[ ]+")))
    (apply #'call-process `(,(car command-parts) nil 0 nil ,@(cdr command-parts)))))

;; (defun nol/exwm-init-hook ()
;;   (exwm/run-in-background "polybar --config=~/dotfiles/polybar/config.ini")
;;   ;; (exwm-randr-refresh)
;;   )

;; (add-hook 'exwm-init-hook 'nol/exwm-init-hook)

;; Only launch polybar if we are using exwm
;; (add-hook 'exwm-init-hook '(lambda ()
;; 			     (add-hook 'od/exwm-dark-theme-hook 'od/start-panel-dark)
;; 			     (add-hook 'od/exwm-dark-theme-hook 'od/toggle-firefox-dark-background)
;; 			     (add-hook 'od/exwm-light-theme-hook 'od/start-panel-light)
;; 			     (add-hook 'od/exwm-light-theme-hook 'od/toggle-firefox-dark-background)))

;; WORK IN PROGRESS
;; When a window is fullscreen, switching theme will put polybar on top which can be annoying (AoE2 for example)
;; (with-selected-frame (exwm-workspace--workspace-from-frame-or-index 0)
;;   (when (exwm-layout--fullscreen-p)
;;     (exwm-layout-unset-fullscreen)))

;; It is a bit annoying when I just want to test my init file
;;(add-hook 'exwm-init-hook '(lambda () (start-process-shell-command "firefox" nil "firefox")))

;; By default, if i have the focus on a remote buffer, and call a function what would
;; create an exwm buffer, the `default-directory' of this exwm buffer is also remote,
;; which is not what I want.
;; Let's see if it works. SO FAR SO GOOD.
;;(add-hook 'exwm-manage-finish-hook '(lambda () (setq default-directory (getenv "HOME"))))
;; HOME doesn't put a trailing /, which bring a weird behavior when using find-file on a exwm
;; buffer. Find-file actually doesn't start in /home/nic/ (it misses a / to do so)
;; (add-hook 'exwm-manage-finish-hook '(lambda () (setq default-directory "~/")))

;; Test to restore Virtual Machine Manager
(defun od/save-virt-manager-buffer (desktop-dirname)
  default-directory)

(add-hook 'exwm-manage-finish-hook
	  (lambda ()
	    (when (and (string= exwm-class-name "Virt-manager")
		       (string= exwm-title "Virtual Machine Manager"))
	      (setq-local desktop-save-buffer #'od/save-virt-manager-buffer))))

(defun od/create-virt-manager-buffer (file-name buffer-name misc)
  (async-start-process "virt-test" "virt-manager" nil))

(add-to-list 'desktop-buffer-mode-handlers '(exwm-mode . od/create-virt-manager-buffer))

;; (exwm-init)
(message "exwm: test2 !")
(exwm-wm-mode)

;; Don't let ediff break EXWM, keep it in one frame
(setq ediff-diff-options "-w"
      ediff-split-window-function 'split-window-horizontally
      ediff-window-setup-function 'ediff-setup-windows-plain)

(load "~/.emacs.d/lisp/circarian-exwm-xsettings.el")

(provide 'init-exwm)
