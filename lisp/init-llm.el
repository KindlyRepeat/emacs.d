(defun nol/format--envvar (env-var value)
  (concat env-var "=" value))

(defun nol/run-pi (&optional path)
  "Run the run-pi.sh script in a new vterm buffer, mounting PATH (default to current directory)."
  (interactive
   (list (read-directory-name
	  (format "Directory to mount in pi (default: %s): " default-directory)
          default-directory nil t)))
  (let* ((thisdir (or path default-directory))
         (vterm-buffer-name (format "*vterm:pi:%s*" thisdir))
         (default-directory thisdir)
	 (env-keys '(("ANTHROPIC_API_KEY" . "anthropic/my-secret-key")
                     ("OPENAI_API_KEY"    . "platform.openai.com/My key")
                     ("TAVILY_API_KEY"    . "tavily.com/default-key")))
	 (vterm-environment
	  (mapcar (lambda (pair)
		    (nol/format--envvar (car pair)
					(password-store-get (cdr pair))))
		  env-keys))

         (buf (vterm vterm-buffer-name)))
    (with-current-buffer buf
      (vterm-insert "~/dotfiles/scripts/bin/run-pi.sh")
      (vterm-send-return))))

(use-package agent-shell
  :commands
  (agent-shell-pi-start-agent
   agent-shell-openai-start-codex)
  :custom
  (agent-shell-header-style 'graphical)
  (agent-shell-session-strategy 'new)
  (agent-shell-pi-acp-command '("/home/nic/dotfiles/scripts/bin/guix-shell-pi.sh" "pi-acp"))
  :config
  (setq agent-shell-openai-codex-acp-command '("codex-acp"))
  ;; (setq agent-shell-openai-codex-acp-command '("/gnu/store/xqqhv4a5qmcmj7p6cbnlj8sxfbgz43ay-node-agentclientprotocol-codex-acp-1.0.0/bin/codex-acp"))

  ;; Updated configuration need to new codex-acp (https://github.com/agentclientprotocol/codex-acp)
  (defun agent-shell-openai-make-codex-config ()
    "Create a Codex agent configuration.

  Returns an agent configuration alist using `agent-shell-make-agent-config'."
    (when (and (boundp 'agent-shell-openai-key) agent-shell-openai-key)
      (user-error "Please migrate to use agent-shell-openai-authentication and eval (setq agent-shell-openai-key nil)"))
    (agent-shell-make-agent-config
     :identifier 'codex
     :mode-line-name "Codex"
     :buffer-name "Codex"
     :shell-prompt "Codex> "
     :shell-prompt-regexp "Codex> "
     :welcome-function #'agent-shell-openai--codex-welcome-message
     :icon-name "openai.png"
     :needs-authentication t
     :default-model-id (lambda ()
                         (if (functionp agent-shell-openai-default-model-id)
                             (funcall agent-shell-openai-default-model-id)
                           agent-shell-openai-default-model-id))
     :default-session-mode-id (lambda () agent-shell-openai-default-session-mode-id)
     :authenticate-request-maker
     (lambda ()
       (cond
        ((map-elt agent-shell-openai-authentication :api-key)
         (let ((api-key (agent-shell-openai-key)))
           (unless api-key
             (user-error "Please set your `agent-shell-openai-authentication'"))
           (acp-make-authenticate-request
            :method-id "api-key"
            :meta `((:api-key . ((:apiKey . ,api-key)))))))
        ((map-elt agent-shell-openai-authentication :codex-api-key)
         (let ((codex-key (agent-shell-openai-key)))
           (unless codex-key
             (user-error "Please set your `agent-shell-openai-authentication'"))
           (acp-make-authenticate-request
            :method-id "api-key"
            :meta `((:api-key . ((:apiKey . ,codex-key)))))))
        (t
         (acp-make-authenticate-request :method-id "chat-gpt"))))
     :client-maker (lambda (buffer)
                     (agent-shell-openai-make-codex-client :buffer buffer))
     :install-instructions "See https://github.com/agentclientprotocol/codex-acp for installation.")))

(use-package gptel
  :commands (gptel)
  :custom
  (gptel-default-mode 'org-mode)
  (gptel-include-tool-results t)
  (gptel-prompt-prefix-alist '((markdown-mode . "### ")
			       (org-mode . "* ")
			       (text-mode . "### ")))
  (gptel-response-prefix-alist '((markdown-mode . #1="")
				 (org-mode . "** Assistant: \n")
				 (text-mode . #1#)))
  :init
  (defun nol/gptel-session (query)
    "Start a GPTel session with a unique buffer name and prompt for QUERY."
    (interactive "sEnter your query: ")
    (let* ((uuid (string-trim (shell-command-to-string "uuidgen")))
           (short-uuid (substring uuid 0 8))
           (session (format "*gptel - %s*" short-uuid)))
      (with-selected-window
          (display-buffer (gptel session nil query))
	(gptel-send))))
  :config
  ;; (setq gptel-model 'gpt-5.5)
  ;; (setq gptel-backend (gptel-make-openai-oauth "OpenAI Codex"))
  (setq gptel-backend (gptel-make-openai-oauth "gptel: OpenAI Codex"))
  (setq gptel-model "gpt-5.5")
  ;; (setq gptel-backend (gptel-make-openai "OpenRouter"
  ;; 			:host "openrouter.ai"
  ;; 			:endpoint "/api/v1/chat/completions"
  ;; 			:stream t
  ;; 			:key '(lambda () (password-store-get "openrouter.ai/key"))
  ;; 			:models '(anthropic/claude-opus-4.8
  ;; 				  anthropic/claude-sonnet-4.6
  ;; 				  deepseek/deepseek-v4-flash
  ;; 				  deepseek/deepseek-v4-pro
  ;; 				  z-ai/glm-5.2
  ;; 				  moonshotai/kimi-k2.6)))
  )

(use-package gptel-integrations
  :after gptel)

(use-package mcp
  :after (gptel gptel-integrations)
  :custom (mcp-hub-servers
           `(("searxng" . ( :command "node"
			    :args ("/home/nic/src/mcp-searxng/dist/index.js")
			    :env (:SEARXNG_URL "http://localhost:8888")))
	     ("gpt-researcher" . ( :command "python3"
				   :args ("/home/nic/src/gptr-mcp/server.py")
				   :env ( :OPENAI_API_KEY ,(password-store-get "platform.openai.com/My key")
					  :RETRIEVER "searx"
					  :SEARX_URL "http://localhost:8888")))))
  :config (require 'mcp-hub)
  :hook (after-init . mcp-hub-start-all-server))

(provide 'init-llm)
