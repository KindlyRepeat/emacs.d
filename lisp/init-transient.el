;; -*- lexical-binding: t; -*-

(use-package transient
  :bind
  (("C-x ?" . od/top-level-transient)
   :map cider-mode-map
   ("C-c ?" . od/cider-transient)
   :map cider-repl-mode-map
   ("C-c ?" . od/cider-transient))
  :config
    (transient-define-prefix od/pass-transient ()
    "Password store"
    ["Password store"
     ["Existing password"
      ("y" "Yank" od/password-store-yank)
      ("w" "Copy" password-store-copy)
      ("e" "Edit" password-store-edit)
      ]
     ["New password"
      ("g" "Generate" password-store-generate)
      ("i" "Insert" password-store-insert)
      ]
     ])

  (transient-define-prefix od/cider-transient ()
    "Cider"
    ["Cider"
     ["Help"
      ("a" "Apropos"     cider-apropos)
      ("b" "Browse ns"   cider-browse-ns)
      ("c" "Clojuredocs" cider-clojuredocs)
      ("d" "Doc"         cider-doc)
      ]
     ]
    )

  (transient-define-prefix od/config-transient ()
    "Emacs configuration"
    ["Emacs configuration"
     ("i" "Imenu" od/config-consult-imenu-multi)
     ("g" "Grep" od/config-consult-grep)
     ]
    )

  (transient-define-prefix od/denote-transient ()
    "Denote"
    ["Denote"
     ("c" "Create note" denote)
     ("f" "Find note" od/denote-find-file)
     ]
    )

  (transient-define-prefix od/top-level-transient ()
    "Top-level"
    ["Top-level menu"
     ("c" "Emacs configuration" od/config-transient)
     ("d" "Denote" od/denote-transient)
     ("p" "Password store" od/pass-transient)
     ]
    )
  (transient-define-prefix od/help-transient ()
    ["Help"
     ["Describe"
      ("v" "Variable" describe-variable)
      ("f" "Function" describe-function)
      ("k" "Key" describe-key)
      ("o" "Symbol" describe-symbol)]
     ["Emacs"
      ("n" "View Emacs News" view-emacs-news)
      ("p" "View Emacs Problems" view-emacs-problems)]
     ["Find"
      ("l" "Find Library" find-library)
      ("w" "UNIX man page" consult-man)]
     ["Info"
      ("m" "Display Info Manual" info-display-manual)
      ("e" "Display Emacs Manual" info-emacs-manual)]]))

(provide 'init-transient)
