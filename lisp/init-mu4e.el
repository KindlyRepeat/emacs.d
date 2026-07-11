(use-package mu4e
  :if (and (executable-find "mu")
	   (executable-find "offlineimap"))
  :demand t
  :bind
  ("C-x m" . mu4e~headers-jump-to-maildir)
  :config
  ;; Set defaut values
  (mu4e t)
  (setq mail-user-agent 'mu4e-user-agent)
  (setq mu4e-sent-folder "/Gmail/[Gmail].Sent Mail")
  (setq mu4e-drafts-folder "/Gmail/[Gmail].Drafts")
  (setq mu4e-trash-folder "/Gmail/[Gmail].Trash")
  (setq mu4e-compose-dont-reply-to-self t)
  (setq smtpmail-default-smtp-server "smtp.gmail.com")
  (setq smtpmail-local-domain "gmail.com")
  (setq smtpmail-smtp-server "smtp.gmail.com")
  (setq smtpmail-stream-type 'starttls)
  (setq smtpmail-smtp-service 587)
  (setq mu4e-get-mail-command "offlineimap -o")
  (setq mu4e-completing-read-function 'completing-read)
  (setq mu4e-save-multiple-attachments-without-asking t)
  (setq message-kill-buffer-on-exit t)
  (setq message-send-mail-function 'smtpmail-send-it)
  (custom-set-variables
   '(mu4e-attachment-dir "/home/nic/Downloads"))
  (setq mu4e-update-interval 300)
  (setq mu4e-hide-index-messages t)

  (setq mu4e-org-contacts-file "~/org/contacts.org")

  (setq mu4e-headers-fields '((:from . 25)
			    (:subject . 90)
			    (:human-date)))

  ;; Type 'a V' to view an email in the browser
  (add-to-list 'mu4e-view-actions '("ViewInBrowser" . mu4e-action-view-in-browser) t)

  (setq mu4e-contexts
	`(
          ,(make-mu4e-context
            :name "gmail"
            :match-func (lambda (msg) (when msg (mu4e-message-contact-field-matches msg :to "nodermattlemay@gmail.com")))
            :vars '((mu4e-drafts-folder . "/Gmail/[Gmail].Drafts")
		    (mu4e-attachment-dir "~/Downloads")
                    (mu4e-sent-folder . "/Gmail/[Gmail].Sent Mail")
                    (mu4e-trash-folder . "/Gmail/[Gmail].Trash")
                    (user-mail-address . "nodermattlemay@gmail.com")
                    (smtpmail-default-smtp-server . "smtp.gmail.com")
                    (smtpmail-local-domain . "gmail.com")
                    (smtpmail-smtp-user . "nodermattlemay")
                    (smtpmail-smtp-server . "smtp.gmail.com")
                    ;;(smtpmail-stream-type . 'starttls)
                    ;;(message-send-mail-function . 'smtpmail-send-it)
                    (smtpmail-smtp-service . 587)))
          ,(make-mu4e-context
            :name "uqam"
            :match-func (lambda (msg) (when msg (mu4e-message-contact-field-matches msg :to "gk691095@ens.uqam.ca")))
            :vars '((mu4e-draft-folder . "/Outlook/Drafts")
                    (mu4e-sent-folder . "/Outlook/Sent Items")
                    (mu4e-trash-folder . "/Outlook/Trash/")
                    (user-mail-address . "odermatt-lemay.nicolas@courrier.uqam.ca")
                    (mu4e-attachment-dir . "~/Downloads")
                    (smtpmail-default-smtp-server . "smtp.office365.com")
                    (smtpmail-local-domain . "courrier.uqam.ca")
                    (smtpmail-smtp-user . "gk691095@ens.uqam.ca")
                    (smtpmail-smtp-server . "smtp.office365.com")
                    (smtpmail-smtp-service . 587)))))
  
  (add-hook 'mu4e-compose-mode-hook 'flyspell-mode))
