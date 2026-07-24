;; -*- lexical-binding: t; -*-

;; It is necessary to set `default-directory' to a local directory. Otherwise, it will try to execute the
;; program on a remote host if the buffer is remote.
(defun nol/volume-up ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "pulsemixer --change-volume +2")
    (when (fboundp 'awesome-tray-volume-refresh) (awesome-tray-volume-refresh))))

(defun nol/volume-down ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "pulsemixer --change-volume -2")
    (when (fboundp 'awesome-tray-volume-refresh) (awesome-tray-volume-refresh))))

(defun nol/volume-mute ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "pulsemixer --set-volume 0")
    (when (fboundp 'awesome-tray-volume-refresh) (awesome-tray-volume-refresh))))

(defun nol/brightness-up ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightnessctl set +5% &>/dev/null")))

(defun nol/brightness-up ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightnessctl set +5% &>/dev/null")))

(defun nol/brightness-down ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightnessctl --min-value=1 set 5%- &>/dev/null")))

(defun nol/brightness-up-monitor-1 ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightness-display-port-0 +")))

(defun nol/brightness-down-monitor-1 ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightness-display-port-0 -")))

(defun nol/brightness-up-monitor-2 ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightness-hdmi-0 +")))

(defun nol/brightness-down-monitor-2 ()
  (interactive)
  (let ((default-directory (getenv "HOME")))
    (shell-command "brightness-hdmi-0 -")))

(defun nol/exwm-layout-toggle-fullscreen (arg)
  "Make window ID fullscreen. If called with a prefix, unset it"
  (interactive "p")
  (if arg
      (exwm-layout-unset-fullscreen)
    (exwm-layout-set-fullscreen)))

(defun nol/configure-window-by-class ()
  (interactive)
  (pcase exwm-class-name
    ("Emacs" (call-interactively #'exwm-input-toggle-keyboard))
    ("Pavucontrol" (exwm-floating-toggle-floating))
    ("Org.gnome.Nautilus" (exwm-floating-toggle-floating))))

(defun nol/set-exwm-simulation-keys ()
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
       ([?\C-k] . [S-end delete])))))

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

(use-package exwm
  :if od/exwm-enabled
  :demand t
  :hook ((exwm-manage-finish . nol/configure-window-by-class)
	 (exwm-manage-finish . nol/set-exwm-simulation-keys)
	 (exwm-update-class . (lambda ()
				(exwm-workspace-rename-buffer exwm-class-name)))
	 (exwm-update-title . (lambda ()
				(pcase exwm-class-name
				  ("Firefox" (exwm-workspace-rename-buffer
					      (format "Firefox: %s"
						      (string-remove-suffix " — Nightly" exwm-title))))))))
  :custom
  ;; Use key-event if unsure
  (exwm-input-global-key `(([XF86AudioRaiseVolume] . nol/volume-up)
			   ([XF86AudioLowerVolume] . nol/volume-down)
			   ([XF86AudioMute] . nol/volume-mute)
			   ([XF86MonBrightnessUp] . nol/brightness-up)
			   ([XF86MonBrightnessDown] . nol/brightness-down)
			   ([S-XF86MonBrightnessUp] . nol/brightness-up-monitor-2)
			   ([S-XF86MonBrightnessDown] . nol/brightness-down-monitor-2)
			   ([?\M-!] . shell-command)
			   ([?\M-&] . async-shell-command)
			   ([?\M-:] . eval-expression)
			   (,(kbd "C-s-p") . winner-undo)
			   (,(kbd "C-s-n") . winner-redo)))
  (exwm-layout-show-all-buffers t)
  (exwm-manage-force-tiling nil)
  (exwm-workspace-show-all-buffers t)
  :config
  ;; prefix `s-e'
  (add-to-list 'exwm-input-prefix-keys 8388709)
  ;; prefix `s-s'
  (add-to-list 'exwm-input-prefix-keys 8388723)
  ;; prefix `s-y'
  (add-to-list 'exwm-input-prefix-keys 8388729)
  ;; prefix `M-s' (otherwise it is grabbed by Firefox
  (add-to-list 'exwm-input-prefix-keys 134217843)
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
  (exwm-input-set-key (kbd "M-o") 'ace-window)
  (exwm-input-set-key (kbd "s-f") 'find-file)
  (exwm-input-set-key (kbd "s-t") 'shell)
  (exwm-input-set-key (kbd "s-T") 'shell-other-window)
  (exwm-input-set-key (kbd "s-p") 'previous-buffer)
  (exwm-input-set-key (kbd "s-n") 'next-buffer)
  ;; (exwm-input-set-key (kbd "s-q") 'window-toggle-side-windows)
  (exwm-input-set-key (kbd "s-h") 'windmove-left)
  (exwm-input-set-key (kbd "s-j") 'windmove-down)
  (exwm-input-set-key (kbd "s-k") 'windmove-up)
  (exwm-input-set-key (kbd "s-l") 'windmove-right)
  (exwm-input-set-key (kbd "s-c") 'quick-calc)
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

  (exwm-wm-mode))

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

(use-package exwm-randr
  :after exwm
  :hook
  (exwm-randr-screen-change . nol/xrandr-set-display)
  :config
  (exwm-randr-mode))

(load "~/.emacs.d/lisp/circarian-exwm-xsettings.el")

(provide 'init-exwm)
