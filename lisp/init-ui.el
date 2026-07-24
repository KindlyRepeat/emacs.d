;; -*- lexical-binding: t; -*-

;;; init-ui.el --- UI-related configuration

;;; Commentary:
;;

;;; Code:

(set-face-attribute 'default nil :family "FiraCode Nerd Font Mono" :height 110)
;; (set-face-attribute 'fixed-pitch nil :family "FiraCode Nerd Font Mono" :height 110)
(set-face-attribute 'fixed-pitch nil :family "FiraCode Nerd Font Mono" :height 110)
(set-face-attribute 'variable-pitch nil :family "Fira Sans" :height 115)

;; Lighter font weight in minibuffer
;; (dolist (buffer (list " *Minibuf-0*" " *Minibuf-1*" ))
;;   (when (get-buffer buffer)
;;     (with-current-buffer buffer
;;       (face-remap-add-relative 'bold :weight 'normal)
;;       (face-remap-add-relative 'default :weight 'light))))

;; (add-hook 'minibuffer-setup-hook
;;           '(lambda()
;;              (face-remap-add-relative 'bold :weight 'normal)
;;              (face-remap-add-relative 'default :weight 'light)))

;; Keep this package first as it load a modus themes and enable the use of
;; `modus-themes-with-colors' macro.
(use-package circadian
  :demand t
  :custom
  (circadian-verbose t)
  (circadian-themes '((:sunrise . modus-operandi)
		      (:sunset . modus-vivendi)))
  :config
  (when od/exwm-enabled
    (setq circadian-after-load-theme-hook '(nol/set-xsettings-theme)))

  (circadian-setup))

;; Do not use-package as its a theme, not a package !
(require-theme 'modus-themes)

(setopt modus-themes-bold-constructs t)
(setopt modus-themes-italic-constructs t)
(setopt modus-themes-mixed-fonts t)

;; (modus-themes-with-colors
;;   (custom-set-faces
;;    `(mode-line-buffer-id ((,c :foreground "#000000")))))

(setq modus-themes-common-palette-overrides
      `(
        ;; From the section "Make the mode line borderless"
        (border-mode-line-active unspecified)
        (border-mode-line-inactive unspecified)
	;; Make it closer to the background color
	(bg-mode-line-active bg-inactive)
	(bg-mode-line-inactive bg-dim)
	;; Colorful background for active tab
	(bg-tab-bar bg-inactive)
        (bg-tab-current bg-cyan-subtle)
        (bg-tab-other bg-dim)))

;; Do not set a background color as moody-tab will overwrite it.
(defface nol/mode-line-selected-buffer-id
  '((t :inherit bold))
  "Face for the buffer id in the selected window's mode line.")

(defun nol/set-modus-mode-line-faces ()
  (modus-themes-with-colors
    (custom-theme-set-faces
     'user
     `(nol/mode-line-selected-buffer-id
       ((t (:inherit bold :foreground ,accent-0)))))))

(add-hook 'modus-themes-after-load-theme-hook #'nol/set-modus-mode-line-faces)
(nol/set-modus-mode-line-faces)

(defun nol/propertized-buffer-identification (fmt)
  "Like `propertized-buffer-identification', but use a special face in the selected window."
  (list
   (propertize fmt
               'face (if (mode-line-window-selected-p)
                         'nol/mode-line-selected-buffer-id
                       'mode-line-buffer-id)
               'help-echo
               (purecopy "Buffer name
mouse-1: Previous buffer
mouse-3: Next buffer")
               'mouse-face 'mode-line-highlight
               'local-map mode-line-buffer-identification-keymap)))

(setq-default mode-line-buffer-identification
              '(:eval (nol/propertized-buffer-identification "%12b")))

;; Set configuration per machine and fix some faces because `base16-theme.el' does a poor job.
;; TODO: Set per machine with a fallback that would work on any machine
;; TODO: Rewrite with modus-themes-with-colors
(defun nol/custom-set-faces ()
    (custom-theme-set-faces
     'user
     '(default ((t (:family "FiraCode Nerd Font Mono" ;; :height 113
			    :weight regular))))
     '(fixed-pitch ((t (:family "FiraCode Nerd Font Mono" ;; :height 113
				:weight regular))))
     '(variable-pitch ((t (:family "Atkinson Hyperlegible" ;; :height 125
				   :weight regular))))
					;
     ;; mode-line should have height 0.9 and a box of width 1
     ;; mode-line-active should inherit mode-line but with background and foreground of default
     ;; `(mode-line ((t (:height 0.9 :box (:line-width 1 :color ,(face-attribute 'default :foreground))))))
     ;; `(mode-line-active ((t ( :inherit mode-line
     ;; 			      :foreground ,(face-attribute 'default :foreground)
     ;; 			      :background ,(face-attribute 'default :background)))))
     ;; `(mode-line-inactive ((t ( :inherit mode-line
     ;; 				:foreground ,(face-attribute 'base16-base03 :background)
     ;; 				:background ,(face-attribute 'base16-base01 :background)))))

     ;; 				      ))))
     ;; ;; `(mode-line-active ((t (:inherit header-line :height 0.8 :foreground ,(face-attribute 'default :foreground) :box nil))))
     '(highlight ((t (:inherit match))))
     '(mode-line-buffer-id ((t (:inherit bold))))
     `(header-line ((t ( :inherit mode-line-inactive
			 :box ( :line-width 1
				:color ,(face-attribute 'mode-line :background)
				:style nil)))))
     ;; '(mode-line-inactive ((t (:inherit mode-line))))

     ;; '(mode-line ((t (:box (:line-width -1 :style released-button)) :inverse-video t)))
     ;; '(mode-line-active ((t (:inherit mode-line))))
     ;; '(mode-line-inactive ((t (:inherit mode-line :weight light))))

     '(org-block ((t (:inherit fixed-pitch))))
     '(org-code ((t (:inherit (shadow fixed-pitch)))))
     '(org-document-info-keyword ((t (:inherit (shadow fixed-pitch)))))
     '(org-indent ((t (:inherit (org-hide fixed-pitch)))))
     '(org-link ((t (:underline t))))
     '(org-meta-line ((t (:inherit (font-lock-comment-face fixed-pitch)))))
     '(org-property-value ((t (:inherit fixed-pitch))) t)
     '(org-special-keyword ((t (:inherit (font-lock-comment-face fixed-pitch)))))
     '(org-table ((t (:inherit fixed-pitch))))
     '(org-tag ((t (:inherit (shadow fixed-pitch) :weight bold :height 0.8))))
     '(org-verbatim ((t (:inherit (shadow fixed-pitch)))))

     '(org-document-title ((t (:family "Iosevka Aile" :height 2.00 :weight bold :underline t))))
     '(org-level-1 ((t (:inherit outline-1 :weight semibold))))
     '(org-level-2 ((t (:inherit outline-2 :weight semibold))))
     '(org-level-3 ((t (:inherit outline-3 :weight semibold))))
     '(org-level-4 ((t (:inherit outline-4 :weight semibold))))
     '(org-level-5 ((t (:inherit outline-5 :weight semibold))))
     '(org-level-6 ((t (:inherit outline-6 :weight semibold))))
     '(org-level-7 ((t (:inherit outline-7 :weight semibold))))
     '(org-level-8 ((t (:inherit outline-8 :weight semibold))))))

(defun nol/fix-gnus-modus-face-cycle (theme &rest _)
  "Prevent a Gnus/Modus inheritance cycle in Emacs 31."
  (when (and (string-prefix-p "modus-" (symbol-name theme))
	     (facep 'gnus-group-news-6))
    (set-face-attribute 'gnus-group-news-6 nil :inherit nil)))

(advice-add 'load-theme :before #'nol/fix-gnus-modus-face-cycle)

(defun nol/set-theme (theme-or-name)
  (interactive
   (list
    (intern (completing-read "Load custom theme: "
                             (mapcar #'symbol-name
				     (custom-available-themes))))))
  "Load `THEME' and disable currently enabled themes."
  (let ((theme-or-name (if (stringp theme-or-name)
			   (intern theme-or-name)
			 theme-or-name)))
    (mapc #'disable-theme custom-enabled-themes)
    (load-theme theme-or-name t)
    (nol/custom-set-faces)))

;; Might wanna take a look at `modify-all-frame-parameters'
(defun od/set-all-fonts (fixed-face variable-face default-height &optional variable-factor)
  "Set FIXED-FACE and VARIABLE-FACE fonts with DEFAULT-HEIGHT for all frames.
Optionally, change the size of VARIABLE-FACE fonts according to VARIABLE-FACTOR."
  (let ((vf (or variable-factor 1.0)))
    (set-face-attribute 'default nil
			:family fixed-face
			:height default-height
			:weight 'regular)
    (set-face-attribute 'fixed-pitch nil
			:family fixed-face
			:weight 'regular)
    (set-face-attribute 'variable-pitch nil
			:family variable-face
			:height vf
			:weight 'regular)
    (set-face-attribute 'mode-line-active nil ;; Save a bit of screen estate by reducing mode-line height
			:height 0.9)
    (set-face-attribute 'mode-line-inactive nil
			:height 0.9)))

;; Set fonts per machine
;; If you just installed the font, restart Emacs for the font to be accessible
;; (pcase (system-name)
;;   ("exaltation"
;;    (od/set-all-fonts "Roboto Mono" "Ubuntu" 100))
;;   ("caconym"
;;    (od/set-all-fonts "Roboto Mono" "Ubuntu" 90 1.1))
;;   ("perfidy"
;;    (od/set-all-fonts "FiraCode Nerd Font" "Fira Sans" 105 1.0))
;;   (_
;;    (od/set-all-fonts "DejaVu Sans Mono" "DejaVu Sans" 90 1.1)))
;; TODO: Maybe (set-face-attribute 'default nil :family "Iosevka Comfy Wide" :height 120)

(defvar tinty-emacs-directory (concat (getenv "XDG_DATA_HOME")
				      "/tinted-theming/tinty/repos/tinted-emacs"))

;; Automatically set Emacs theme when `org.base16.theme current-theme' (a custom schema) changes.
(require 'dbus)

(defun my-dconf-notify-handler (path changed-keys tag)
  "Handler for dconf Notify signals."
  (message "dconf key changed: %s" path)
  ;; Example: call gsettings to get new value
  (when (string= path "/org/base16/theme/current-theme")
    (let ((value (string-trim
                  (shell-command-to-string
                   "gsettings get org.base16.theme current-theme")
		  "[\n']+" "[\n']+")))
      (nol/set-theme (intern value))
      (message "New value: %s" value))))

(dbus-register-signal
 :session			 ;; listen on the session bus
 "ca.desrt.dconf"		 ;; service name
 "/ca/desrt/dconf/Writer/user"	 ;; object path
 "ca.desrt.dconf.Writer"	 ;; interface
 "Notify"			 ;; signal name
 #'my-dconf-notify-handler)



(defun nol/xsettings-net-theme-name ()
  "Call 'dump_xsettings' and return the value of 'Net/ThemeName', or nil if xsettingsd is not running."
  (let ((output (shell-command-to-string "dump_xsettings")))
    (if (string= (substring output 0 1) "1")
        nil  ;; xsettingsd is not running
      ;; Parse output for 'Net/ThemeName'
      (with-temp-buffer
        (insert output)
        (goto-char (point-min))
        (if (re-search-forward "^Net/ThemeName \"\\([^\"]+\\)\"" nil t)
            (match-string 1)
          nil)))))

(use-package base16-theme
  :load-path tinty-emacs-directory
  :init
  (add-to-list 'custom-theme-load-path (concat tinty-emacs-directory "/build"))
  ;; If `xsettingsd' is running, set Emacs theme accordingly.
  (setq xsettings-net-theme-name (nol/xsettings-net-theme-name))
  :config
  (when xsettings-net-theme-name
    (nol/set-theme xsettings-net-theme-name))



  ;; (defun od/set-base16-theme (base16-theme)
  ;;   "Load `BASE16-THEME'."
  ;;   ;; Disable all enabled themes.
  ;;   (mapc (lambda (theme) (disable-theme theme)) custom-enabled-themes)
  ;;     ;; Load the new theme
  ;;   (load-theme base16-theme t))
  )

;; Use linum-mode for versions before 29.1
(use-package display-line-numbers
  :if (not (version< emacs-version "29"))
  :hook ((prog-mode . (lambda () (display-line-numbers-mode 1)))
	 (text-mode . (lambda () (display-line-numbers-mode -1)))))

(use-package ef-themes
  :disabled t
  :demand t
  :hook ((emacs-startup . (lambda () (od/set-ef-initial-theme (od/get-current-desktop-theme))))
	 (ef-themes-post-load . od/ef-themes-custom-faces)
	 (ef-themes-post-load . od/ef-themes-set-matching-gtk-theme)
	 (ef-themes-post-load . od/ef-themes-set-matching-iconset)
	 (ef-themes-post-load . od/ef-themes-set-matching-wallpaper)
	 (ef-themes-post-load . od/unfuck-mode-line-face))
  :config
  (setq ef-themes-headings		; Increase the size of org mode files title
	'((0 regular 1.2)))

    (defun od/dipc-generate-json-palette-from-theme (theme)
    "From a given theme, generate a JSON string that can be passed to `dipc' to convert the color palette of an image."
    (concat "'"
	    "JSON: "
	    (json-encode
	     `(,(cons theme
		      (remq nil (mapcar (lambda (color)
					  (when (and (string-or-null-p (cadr color))
						     (string-match-p "^#.*" (cadr color)))
					    (cons (car color)
						  (cadr color))))
					(ef-themes--palette-value theme))))))
	    "'"))

  ;; TODO: Use XDG_DOWNLOAD_DIR instead.
  (defun od/dipc-start-process (theme image)
    "Call `dipc', converting `image' according to `theme'."
    (start-process-shell-command "dipc conversion"
				 "*dipc conversion process*"
				 (concat "~/.cargo/bin/dipc "
					 (od/dipc-generate-json-palette-from-theme theme)
					 " "
					 image
					 " --dir-output ~/downloads")))

  (defun od/ef-themes-set-matching-gtk-theme ()
    "Change the GTK theme for one that matches the current ef-theme.
This function is meant to be called from `ef-themes-post-load-hook'.
The matching GTK themes are generated with the script `generate-color-scheme.sh'
from `flat-remix-gtk'. Use the helper functions `od/generate-color-theme-command'
and `od/generate-color-themes' to generate themes."
    (when (string= od/desktop-environment "XFCE")
      (let* ((current-ef-theme (ef-themes--current-theme))
	     (theme-dark-p (member current-ef-theme ef-themes-dark-themes))
	     (gtk-theme (concat (symbol-name current-ef-theme)
				(when theme-dark-p "-Dark"))))
	(if (file-exists-p (concat (getenv "HOME")
				   "/.local/share/themes/"
				   gtk-theme))
	    (progn
	      (start-process-shell-command "GTK theming"
					   "*GTK theming*"
					   (concat "xfconf-query -c xsettings -p /Net/ThemeName -s "
						   gtk-theme))
	      (start-process-shell-command "GTK theming"
					   "*GTK theming*"
					   (concat "xfconf-query -c xfwm4 -p /general/theme -s "
						   gtk-theme)))
	  (user-error "Could not find GTK theme %s. Use `oomox-gtk-theme' to create it." gtk-theme)))))

  (defvar tricolorize-executable "tricolorize")

  (defun od/colorize-image-according-to-theme (image theme)
    "Colorize `IMAGE' according to the `bg-mode-line' face of `THEME'."
    (let* ((theme-name (symbol-name theme))
	   (output-image (concat (file-name-sans-extension image)
				 "-"
				 theme-name
				 (file-name-extension image t))))
      (let-alist (ef-themes--palette-value theme)
	(start-process-shell-command "Colorize image"
				     "*Colorize image*"
				     (concat tricolorize-executable " -m "
					     "\"" (car .bg-mode-line) "\" "
					     image " "
					     output-image)))))

  (defvar wallpaper-light-template "~/nc/themes/solar-flares-light.jpg")
  (defvar wallpaper-dark-template "~/nc/themes/solar-flares-dark.jpg")

  ;; TODO: Use xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitoreDP-1/workspace0/last-image -s
  (defun od/ef-themes-set-matching-wallpaper ()
    "Set XFCE wallpaper according to `ef-themes--current-theme'."
    (when (string= od/desktop-environment "XFCE")
      (let* ((ef-theme (ef-themes--current-theme))
	     (theme-dark-p (member ef-theme ef-themes-dark-themes))
	     (template (if theme-dark-p wallpaper-dark-template wallpaper-light-template))
	     (wallpaper (concat (file-name-sans-extension template)
				"-"
				(symbol-name ef-theme)
				(file-name-extension template t))))
	(if (file-exists-p wallpaper)
	    (start-process-shell-command "Set wallpaper"
					 "*Set wallpaper*"
					 (concat "xfconf-query "
						 "--channel xfce4-desktop "
						 "--property /backdrop/screen0/monitoreDP-1/workspace0/last-image "
						 "--set " wallpaper))
	  (user-error "Could not find wallpaper %s. See `~/nc/themes/README.org to generate the wallpaper" wallpaper)))))

  ;; TODO: put tricolorize in my scripts. Will they be executable is symlinked from GUIX ?
  ;; TODO : I should probably send a patch to home-dotfiles-configuration for it to respect the executable bit ?
  ;; (mapc (lambda (theme) (od/colorize-image-according-to-theme "~/nc/themes/solar-flares-light.jpg" theme))
  ;; 	ef-themes-light-themes)
  ;; (mapc (lambda (theme) (od/colorize-image-according-to-theme "~/nc/themes/solar-flares-dark.jpg" theme))
  ;; 	ef-themes-dark-themes)

  (defun od/unfuck-mode-line-face ()
    "Unfuck mode-line face.
Calling `ef-themes-load-random' from `emacsclient' changes the mode-line face
for some reason. Use this function to reset it properly."
    (set-face-attribute 'mode-line nil :foreground (car (alist-get 'fg-mode-line (ef-themes--current-theme-palette))))
    (set-face-attribute 'mode-line nil :background (car (alist-get 'bg-mode-line (ef-themes--current-theme-palette)))))

  (defun od/ef-themes-custom-faces ()
    "Customizations to add to `ef-themes-post-load-hook'."
    (ef-themes-with-colors
      (custom-set-faces
       `(tab-bar ((,c :background ,bg-main)))
       `(tab-bar-tab ((,c :background ,bg-mode-line
			  :box (:line-width 1 :color ,fg-dim))))
       `(tab-bar-tab-inactive ((,c :background ,bg-alt
				   :box (:line-width 1 :color ,fg-dim)))))))

    ;; Those are the variables used when calling `ef-themes-load-random' without a variant.
  (setq ef-themes-default-collection ef-themes-collection
	ef-themes-collection (seq-remove (lambda (_)
					   (member _ (list 'ef-deuteranopia-light
							   'ef-deuteranopia-dark
							   'ef-tritanopia-light
							   'ef-tritanopia-dark
							   'ef-melissa-light
							   'ef-melissa-dark)))
					 ef-themes-default-collection))

    ;; Those are the variables used when calling `ef-themes-load-random' with a variant.
  (setq ef-themes-light-themes (seq-remove (lambda (_)
					     (member _ (list 'ef-deuteranopia-light
							     'ef-tritanopia-light
							     'ef-melissa-light)))
					   ef-themes-light-themes))
  (setq ef-themes-dark-themes (seq-remove (lambda (_)
					    (member _ (list 'ef-deuteranopia-dark
							    'ef-tritanopia-dark
							    'ef-melissa-dark)))
					  ef-themes-dark-themes))

  (defun od/get-current-desktop-theme ()
    "Return the current desktop theme, as a string."
    (cond
     ((string= od/desktop-environment "XFCE")
      (thread-last
	(shell-command-to-string "xfconf-query -c xsettings -p /Net/ThemeName")
	s-chomp))
     ((string= od/desktop-environment "GNOME")
      (thread-last
	(shell-command-to-string "gsettings get org.gnome.desktop.interface gtk-theme")
	s-chomp
	(s-replace "'" "")))
     (t (user-error "Couldn't detect current desktop theme."))))

  (defun od/set-ef-initial-theme (desktop-theme)
    "Load a random ef-theme based on the current desktop theme.
The theme must have the string `dark' in its name for this to work."
    (if (string-match-p "dark" desktop-theme)
	(ef-themes-load-random 'dark)
      (ef-themes-load-random 'light)))

  ;; This only works with `ef-themes' for now. For it to work with other themes,
  ;; I would need a way to get the faces as set by THEME.
  (defun od/themix-oomox-colors-plist (ef-theme)
    "Return a plist of colors suitable to create a GTK theme from EF-THEME."
    (let-alist (ef-themes--palette-value ef-theme)
      `(;; Theme Colors
	(:key "BG"                 :value ,(car .bg-main)       :doc "Background")
	(:key "FG"                 :value ,(car .fg-main)       :doc "Text")
	(:key "HDR_BG"             :value ,(car .bg-dim)        :doc "Header Background. The part of windows including the titlebar and the menus (File, Edit, View, etc). `bg-dim' is the background color of face `menu'")
	(:key "HDR_FG"             :value ,(car .fg-main)       :doc "Header Text")
	(:key "SEL_BG"             :value ,(car .bg-region)     :doc "Selected Background. Selected text, highlighted URL bar in Firefox, etc.")
	(:key "SEL_FG"             :value ,(car .fg-main)       :doc "Selected Text")
	(:key "ACCENT_BG"          :value ,(car .yellow-warmer) :doc "Accent Color (Checkboxes, Radios. Use `yellow-warmer' as it is used by `org-checkbox'.")
	(:key "TXT_BG"             :value ,(car .bg-alt)        :doc "Textbox Background. Use `bg-alt' as it is used by `widget-field'.")
	(:key "TXT_FG"             :value ,(car .fg-main)       :doc "Textbox Text. Use `fg-main' as it is used by `widget-field'.")
	(:key "BTN_BG"             :value ,(car .bg-active)     :doc "Button Background. Use `bg-active' as it is used by `custom-button'.")
	(:key "BTN_FG"             :value ,(car .fg-intense)    :doc "Button Text. Use `fg-intense' as it is used by `custom-button'.")
	(:key "HDR_BTN_BG"         :value ,(car .bg-active)     :doc "Header Button Background. Same as BTN_BG.")
	(:key "HDR_BTN_FG"         :value ,(car .fg-intense)    :doc "Header Button Text. Same as BTN_FG.")
	(:key "WM_BORDER_FOCUS"    :value ,(car .bg-main)       :doc "Focused Window Border. No border for unfocused windows.")
	(:key "WM_BORDER_UNFOCUS"  :value ,(car .bg-main)       :doc "Unfocused Window Border. No border for unfocused windows.")
	(:key "CARET1_FG"          :value ,(car .cursor)        :doc "Textbox Caret.")
	(:key "CARET2_FG"          :value ,(car .cursor)        :doc "BiDi Textbox Caret. Not sure what this is.")
	;; Theme Options
        (:key "ROUNDNESS"          :value "0"                   :doc "Roundness")
	(:key "GRADIENT"           :value "0.0"                 :doc "Gradient")
	(:key "GTK3_GENERATE_DARK" :value ,(if (member
					       ef-theme
					       ef-themes-dark-themes)
					      "True"
					    "False")            :doc "Add Dark Variant"))))

  (defvar od/themix-oomox-change-color-executable "~/src/themix-gui/plugins/theme_oomox/change_color.sh")

  (defun od/themix-oomox-theme-command (ef-theme)
    "Return a command to call to create a GTK theme from EF-THEME."
    (let* ((colors-plist (od/themix-oomox-colors-plist ef-theme))
	   (colors-as-args (apply #'concat
				  (mapcar (lambda (row)
					    (cl-destructuring-bind
						(&key key value &allow-other-keys)
						row
					      (concat key
						      "="
						      (s-chop-prefix "#" value)
						      "\\n")))
					  colors-plist))))
	   (concat od/themix-oomox-change-color-executable " "
		   "-o " (symbol-name ef-theme) (when (member ef-theme ef-themes-dark-themes) "-Dark") " "
		   "-t " "~/.local/share/themes" " "
		   "<(echo -e \""
		   colors-as-args
		   "\")")))


  ;; Call `od/oomox-call-color-theme-command' for all ef-themes.
  ;; (mapc #'od/themix-oomox-create-theme (append ef-themes-light-themes ef-themes-dark-themes))
  (defun od/themix-oomox-create-theme (theme)
    "Create a GTK theme matching EF-THEME
Call the command generated from `od/oomox-generate-color-theme-command'."
    (let* ((name (concat "themix-" (symbol-name theme)))
	   (buffer (s-wrap name "*")))
      (start-process-shell-command name
				   buffer
				   (od/themix-oomox-theme-command theme))))

   (defun od/themix-papirus-iconset-colors-plist (ef-theme)
    "Return a plist of colors suitable to create an iconset from EF-THEME.
The colors needed to colorize the folders icons are calculated from ICONS_COLOR."
    (let-alist (ef-themes--palette-value ef-theme)
      `((:key "ICONS_COLOR"           :value ,(car .bg-mode-line)  :doc "Main color for folder icons")
	(:key "ICONS_SYMBOLIC_ACTION" :value ,(car .yellow-warmer) :doc "Some icons that trigger an action, e.g Bluetooth Adapters")
	(:key "ICONS_SYMBOLIC_PANEL"  :value ,(car .fg-main)       :doc "Some icons in the panel"))))

   (defvar od/themix-papirus-iconset-change-color-executable "~/src/themix-gui/plugins/icons_papirus/change_color.sh")

   (defun od/themix-papirus-iconset-command (ef-theme)
     "Return a command to call to create an iconset from EF-THEME."
     (let* ((colors-plist (od/themix-papirus-iconset-colors-plist ef-theme))
	    (preset-file (make-temp-file (concat (symbol-name ef-theme)
						 "-iconset"))))
       (with-temp-file preset-file
	 (insert (apply #'concat
			(mapcar (lambda (row)
				  (cl-destructuring-bind
				      (&key key value &allow-other-keys)
				      row
				    (concat key
					    "="
					    (s-chop-prefix "#" value)
					    "\n")))
				colors-plist))))
       (concat od/themix-papirus-iconset-change-color-executable " "
	       "-o " (symbol-name ef-theme) " "
	       "-d " "~/.local/share/icons/" (symbol-name ef-theme) " "
	       preset-file)))

  (defun od/themix-papirus-create-iconset (ef-theme)
    "Create a set of icons matching EF-THEME.
Call the command generated from `od/themix-papirus-iconset-command'. The iconset
might need to be put in cache using the command `gtk-update-icon-cache -f
<path-to-iconset>'"
    (let* ((name (concat "themix-papirus-" (symbol-name ef-theme) "-iconset"))
	   (buffer (s-wrap name "*")))
      (start-process-shell-command name
				   buffer
				   (od/themix-papirus-iconset-command ef-theme))))

  (defun od/ef-themes-set-matching-iconset ()
    "..."
    (when (string= od/desktop-environment "XFCE")
      (let* ((current-ef-theme (ef-themes--current-theme))
	     (iconset (concat (symbol-name current-ef-theme))))
	(if (file-exists-p (concat (getenv "HOME")
				   "/.local/share/icons/"
				   iconset))
	    (progn
	      (start-process-shell-command "Iconset theming"
					   "*Iconset theming*"
					   (concat "xfconf-query -c xsettings -p /Net/IconThemeName -s "
						   iconset)))
	  (user-error "Could not find iconset %s. Use `od/themix-papirus-create-iconset' to create it" iconset))))))

(use-package eros
  :demand t
  :config
  (defun edebug-compute-previous-result (previous-value)
    (if edebug-unwrap-results
	(setq previous-value
              (edebug-unwrap* previous-value)))
    (setq edebug-previous-result
          (concat "Result: "
                  (edebug-safe-prin1-to-string previous-value)
                  (eval-expression-print-format previous-value))))

  (defun edebug-previous-result ()
    "Print the previous result."
    (interactive)
    (message "%s" edebug-previous-result))

  (defun adviced:edebug-compute-previous-result (_ &rest r)
    "Adviced `edebug-compute-previous-result'."
    (let ((previous-value (nth 0 r)))
      (if edebug-unwrap-results
          (setq previous-value
		(edebug-unwrap* previous-value)))
      (setq edebug-previous-result
            (edebug-safe-prin1-to-string previous-value))))

  (advice-add #'edebug-compute-previous-result
              :around
              #'adviced:edebug-compute-previous-result)

  (defun adviced:edebug-previous-result (_ &rest r)
    "Adviced `edebug-previous-result'."
    (eros--make-result-overlay edebug-previous-result
      :where (point)
      :duration eros-eval-result-duration))

  (advice-add #'edebug-previous-result
              :around
              #'adviced:edebug-previous-result)

  (eros-mode))

(use-package faces)

;; `initial-frame-alist' and `default-frame-alist' should be set in early-init.el
(use-package frame)

(use-package ligature
  :config
  ;; Enable the "www" ligature in every possible major mode
  (ligature-set-ligatures 't '("www"))
  ;; Enable traditional ligature support in eww-mode, if the
  ;; `variable-pitch' face supports it
  (ligature-set-ligatures 'eww-mode '("ff" "fi" "ffi"))
  ;; Enable all Cascadia and Fira Code ligatures in programming modes
  (ligature-set-ligatures 'prog-mode
                          '(;; == === ==== => =| =>>=>=|=>==>> ==< =/=//=// =~
                            ;; =:= =!=
                            ("=" (rx (+ (or ">" "<" "|" "/" "~" ":" "!" "="))))
                            ;; ;; ;;;
                            (";" (rx (+ ";")))
                            ;; && &&&
                            ("&" (rx (+ "&")))
                            ;; !! !!! !. !: !!. != !== !~
                            ("!" (rx (+ (or "=" "!" "\." ":" "~"))))
                            ;; ?? ??? ?:  ?=  ?.
                            ("?" (rx (or ":" "=" "\." (+ "?"))))
                            ;; %% %%%
                            ("%" (rx (+ "%")))
                            ;; |> ||> |||> ||||> |] |} || ||| |-> ||-||
                            ;; |->>-||-<<-| |- |== ||=||
                            ;; |==>>==<<==<=>==//==/=!==:===>
                            ("|" (rx (+ (or ">" "<" "|" "/" ":" "!" "}" "\]"
                                            "-" "=" ))))
                            ;; \\ \\\ \/
                            ("\\" (rx (or "/" (+ "\\"))))
                            ;; ++ +++ ++++ +>
                            ("+" (rx (or ">" (+ "+"))))
                            ;; :: ::: :::: :> :< := :// ::=
                            (":" (rx (or ">" "<" "=" "//" ":=" (+ ":"))))
                            ;; // /// //// /\ /* /> /===:===!=//===>>==>==/
                            ("/" (rx (+ (or ">"  "<" "|" "/" "\\" "\*" ":" "!"
                                            "="))))
                            ;; .. ... .... .= .- .? ..= ..<
                            ("\." (rx (or "=" "-" "\?" "\.=" "\.<" (+ "\."))))
                            ;; -- --- ---- -~ -> ->> -| -|->-->>->--<<-|
                            ("-" (rx (+ (or ">" "<" "|" "~" "-"))))
                            ;; *> */ *)  ** *** ****
                            ("*" (rx (or ">" "/" ")" (+ "*"))))
                            ;; www wwww
                            ("w" (rx (+ "w")))
                            ;; <> <!-- <|> <: <~ <~> <~~ <+ <* <$ </  <+> <*>
                            ;; <$> </> <|  <||  <||| <|||| <- <-| <-<<-|-> <->>
                            ;; <<-> <= <=> <<==<<==>=|=>==/==//=!==:=>
                            ;; << <<< <<<<
                            ("<" (rx (+ (or "\+" "\*" "\$" "<" ">" ":" "~"  "!"
                                            "-"  "/" "|" "="))))
                            ;; >: >- >>- >--|-> >>-|-> >= >== >>== >=|=:=>>
                            ;; >> >>> >>>>
                            (">" (rx (+ (or ">" "<" "|" "/" ":" "=" "-"))))
                            ;; #: #= #! #( #? #[ #{ #_ #_( ## ### #####
                            ("#" (rx (or ":" "=" "!" "(" "\?" "\[" "{" "_(" "_"
					 (+ "#"))))
                            ;; ~~ ~~~ ~=  ~-  ~@ ~> ~~>
                            ("~" (rx (or ">" "=" "-" "@" "~>" (+ "~"))))
                            ;; __ ___ ____ _|_ __|____|_
                            ("_" (rx (+ (or "_" "|"))))
                            ;; Fira code: 0xFF 0x12
                            ("0" (rx (and "x" (+ (in "A-F" "a-f" "0-9")))))
                            ;; Fira code:
                            "Fl"  "Tl"  "fi"  "fj"  "fl"  "ft"
                            ;; The few not covered by the regexps.
                            "{|"  "[|"  "]#"  "(*"  "}#"  "$>"  "^="))
  ;; Enables ligature checks globally in all buffers. You can also do it
  ;; per mode with `ligature-mode'.
  (global-ligature-mode t))

;; Starting at emacs 29.1, use display-line-numbers-mode
(use-package linum
  :if (version< emacs-version "29.1")
  :init
  (add-hook 'prog-mode-hook #'(lambda () (linum-mode 1)))
  (add-hook 'text-mode-hook #'(lambda () (linum-mode -1))))

(use-package moody
  :demand t
  :hook (;; (post-command . nol/record-selected-window)
	 (buffer-list-update . nol/update-all))
  :init
  ;; Track the current window to control the colors of moody-mode-line-buffer-identification.
  ;; (defvar nol/selected-window nil)

  ;; (defun nol/record-selected-window ()
  ;;   (setq nol/selected-window (selected-window)))

  ;; Not sure if still necessary
  (defun nol/update-all ()
    (force-mode-line-update t))

  ;; Get buffer-id width.
  ;; Add padding
  ;; If smaller than X, return X.
  ;; If larger than Y, return Y and add elipsis
  ;; (defun nol/truncate-buffer-identification (buf-name)
  ;;   "Pad BUF-NAME so all buffer ids in the mode-line have the same width."
  ;;   (require 's)
  ;;   ;; Loop on all visible windows and find the longest buffer-name.
  ;;   (let ((longest-buffer-name-length 0))
  ;;     (walk-windows (lambda (w)
  ;;                     (setq longest-buffer-name-length
  ;;                           (max longest-buffer-name-length
  ;; 				 (length (buffer-name (window-buffer w)))))))
  ;;     ;; We want the mode-`line-buffer-id' to be the same size for all windows, but to have a minimum width.
  ;;     (let* ((padding 2)
  ;;            (min-width 20)
  ;; 	     (max-width 40)
  ;;            (desired-width (max min-width (if (< longest-buffer-name-length max-width)
  ;;                                             longest-buffer-name-length
  ;;                                            max-width)))
  ;; 	     (final-width (+ desired-width padding)))
  ;; 	(s-center final-width buf-name))))

  ;; (defun nol/propertized-buffer-identification (fmt)
;;     "Same as `propertized-buffer-identification' but pick the face according to `nol/selected-window'."
;;     (list (propertize fmt
;; 		      'face (if (eq nol/selected-window (selected-window)) 'mode-line-buffer-id 'fixed-pitch)
;; 		      'help-echo
;; 		      (purecopy "Buffer name
;; mouse-1: Previous buffer\nmouse-3: Next buffer")
;; 		      'mouse-face 'mode-line-highlight
;; 		      'local-map mode-line-buffer-identification-keymap)))

  :config
  (setq-default moody-mode-line-buffer-identification
                '( :eval (moody-tab (car (nol/propertized-buffer-identification "%b"))
				    20 'down)))

  (defun nol/moody-mode-line-height ()
    (+ 3 (frame-char-height)))

  (setq moody-mode-line-height 'nol/moody-mode-line-height
	x-underline-at-descent-line t)
  (moody-replace-mode-line-buffer-identification)
  (moody-replace-vc-mode)
  (moody-replace-eldoc-minibuffer-message-function)

  ;; (setq-default moody-mode-line-buffer-identification
  ;; 		'(:eval
  ;; 		  (moody-tab
  ;; 		   (car
  ;; 		    (nol/propertized-buffer-identification
  ;; 		     (nol/truncate-buffer-identification (buffer-name)))) 0 'down)))


  ;; I want to have the space for 11 characters on each side of the moody buffer id.
  ;; (setq-default moody-mode-line-buffer-identification
  ;; 		'(:eval
  ;; 		  (moody-tab
  ;; 		   (car
  ;; 		    (propertized-buffer-identification
  ;; 		     (string-truncate-left (buffer-name) (- (window-width) 22))))
  ;; 		   20 'up)))
  )

(use-package nerd-icons
  :config
  ;; Used by `nerd-icons-completion' and `nerd-icons-dired'.
  (setq nerd-icons-font-family "FiraCode Nerd Font"))

(use-package nerd-icons-completion
  :unless (string= (tty-type) "linux")	; Those icons can't be displayed on TTYs.
  :demand t
  :custom
  ;; Having the same icon for all items is useless. Though it is useful for buffer
  ;; selection. Use `nf-cod-blank' to have the same alignment between buffer
  ;; selection and the other categories.
  (nerd-icons-completion-category-icons
   '((command nerd-icons-codicon "nf-cod-blank" nerd-icons-blue)
     (theme nerd-icons-codicon "nf-cod-blank" nerd-icons-yellow)
     (symbol nerd-icons-codicon "nf-cod-blank" nerd-icons-dblue)
     (variable nerd-icons-codicon "nf-cod-blank" nerd-icons-lpurple)
     (function nerd-icons-codicon "nf-cod-blank" nerd-icons-blue)
     (package nerd-icons-codicon "nf-cod-blank" nerd-icons-orange)
     (symbol-help nerd-icons-codicon "nf-cod-blank" nerd-icons-lpurple)
     (face nerd-icons-codicon "nf-cod-blank" nerd-icons-pink)
     (input-method nerd-icons-codicon "nf-cod-blank" nerd-icons-blue-alt)
     (org-roam-node nerd-icons-codicon "nf-cod-blank" nerd-icons-silver)
     (imenu nerd-icons-codicon "nf-cod-blank" nerd-icons-lblue)
     (kill-ring nerd-icons-codicon "nf-cod-blank" nerd-icons-silver)
     (coding-system nerd-icons-codicon "nf-cod-blank" nerd-icons-lpurple)
     (library nerd-icons-codicon "nf-cod-blank" nerd-icons-lpurple)
     (nil nerd-icons-codicon "nf-cod-blank" nerd-icons-silver)))
  :config
  (nerd-icons-completion-mode))

(use-package nerd-icons-dired
  :unless (string= (tty-type) "linux")	; Those icons can't be displayed on TTYs.
  :demand t
  :hook ((dired-mode . (lambda ()
			 (unless (file-remote-p dired-directory)
			   (nerd-icons-dired-mode))))))

(use-package prism
  :disabled t
  :demand t
  :after modus-themes
  :hook
  ((emacs-lisp-mode . prism-mode)
   (lisp-interaction-mode . prism-mode)
   (modus-themes-after-load-theme .
				  (lambda ()
				    (prism-set-colors
				      :desaturations '(0) ; do not change---may lower the contrast ratio
				      :lightens '(0)      ; same
				      :colors (modus-themes-with-colors
						(list fg-main
						      magenta
						      cyan-alt-other
						      magenta-alt-other
						      blue
						      magenta-alt
						      cyan-alt
						      red-alt-other
						      green
						      fg-main
						      cyan
						      yellow
						      blue-alt
						      red-alt
						      green-alt-other
						      fg-special-warm))
				      :parens-fn #'(lambda (color)
						     (prism-blend color
								  (face-attribute 'default :background)
								  0.25))))))
  :config
  (setq prism-num-faces 16
	prism-parens t))

(use-package shrface
  :if (unless (string= (system-name) "perfidy"))
  :after eww
  :bind (:map shrface-mode-map
	      (("C-c C-p" . shrface-previous-headline)
	       ("C-c C-n" . shrface-next-headline)
	       ("TAB" . shrface-outline-cycle)))
  :hook ((eww-mode . shrface-mode))
  :config
  (shrface-basic)
  (shrface-trial)
  (setq shrface-href-versatile t))

(use-package spacious-padding
  :demand t
  :custom
  (spacious-padding-widths '( :internal-border-width 5
			      :header-line-width 4
			      :mode-line-width 2
			      :tab-width 10
			      :right-divider-width 10
			      :scroll-bar-width 8
			      :fringe-width 2))
  :custom
  (spacious-padding-mode 1))

(provide 'init-ui)

;;; init-ui.el ends here
