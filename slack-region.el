;;; slack-region.el --- Send region text to Slack via shell script -*- lexical-binding: t; -*-

(defgroup my-slack-region nil
  "Send selected region to Slack."
  :group 'external
  :prefix "my/slack-")

(defcustom my/slack-sender-cmd "/path/to/send-slack"
  "Shell command to post text to Slack. Must accept -c <channel_id> and read stdin."
  :type 'string)

(defcustom my/slack-channel-alist
  '(("random"      . "CC123456")
    ("emacs-topic" . "CABCDEFG")) ; 例：プライベートは G で始まる
  "Alist of Slack channels: (NAME . CHANNEL-ID). NAME is what you type; ID is C.../G..."
  :type '(alist :key-type string :value-type string))

(defcustom my/slack-current-channel-name nil
  "Current channel NAME to send messages to (key of `my/slack-channel-alist')."
  :type '(choice (const :tag "unset" nil) string))

(defun my/slack--channel-id (name)
  "Resolve channel NAME to ID from `my/slack-channel-alist'."
  (or (cdr (assoc-string name my/slack-channel-alist t))
      (user-error "Unknown channel name: %s (edit `my/slack-channel-alist')" name)))

(defun my/slack-current-channel ()
  "Return current (NAME . ID), prompting if unset."
  (let* ((name (or my/slack-current-channel-name
                   (completing-read "Select Slack channel: "
                                    (mapcar #'car my/slack-channel-alist)
                                    nil t))))
    (cons name (my/slack--channel-id name))))

(defun my/slack-set-channel (&optional name)
  "Set current Slack channel by NAME (with completion). Persist to customize."
  (interactive)
  (let* ((nm (or name
                 (completing-read "Set Slack channel: "
                                  (mapcar #'car my/slack-channel-alist)
                                  nil t))))
    (setq my/slack-current-channel-name nm)
    ;; 永続化（~/.emacs.d/custom.el 等へ）
    (customize-save-variable 'my/slack-current-channel-name nm)
    (message "Slack channel set to %s (id=%s)" nm (my/slack--channel-id nm))))

(defun my/slack-add-channel (name id)
  "Add (NAME . ID) to `my/slack-channel-alist' and persist."
  (interactive "sNew channel NAME: \nsChannel ID (C.../G...): ")
  (setq my/slack-channel-alist
        (cons (cons name id)
              (assq-delete-all name my/slack-channel-alist)))
  (customize-save-variable 'my/slack-channel-alist my/slack-channel-alist)
  (message "Added %s -> %s" name id))

(defun my/slack-send-region (&optional force-prompt)
  "Send active region to Slack.
If FORCE-PROMPT (C-u) is non-nil, prompt channel even if current is set."
  (interactive "P")
  (unless (use-region-p)
    (user-error "リージョンが選択されていません"))
  (let* ((beg (region-beginning))
         (end (region-end))
         (deactivate-mark nil) ;; 対話でマークが消えないように
         (pair (if force-prompt
                   (let ((nm (completing-read "Select Slack channel: "
                                              (mapcar #'car my/slack-channel-alist)
                                              nil t)))
                     (cons nm (my/slack--channel-id nm)))
                 (my/slack-current-channel)))
         (name (car pair))
         (id   (cdr pair))
         (buf  (get-buffer-create "*slack-send*"))
         exit-code)
    ;; 出力バッファだけを消す
    (with-current-buffer buf (erase-buffer))
    ;; ★ ここが肝：現在バッファは切り替えず、元バッファの beg..end を送る
    (setq exit-code
          (call-process-region beg end
                               my/slack-sender-cmd
                               nil buf nil
                               "-c" id))
    (if (and (integerp exit-code) (zerop exit-code))
        (message "Sent to #%s" name)
      (pop-to-buffer "*slack-send*")
      (error "Slack 送信に失敗しました（*slack-send* を確認）"))))


;; 便利キー
(global-set-key (kbd "C-c s s") #'my/slack-send-region)  ; そのまま送信
(global-set-key (kbd "C-c s c") #'my/slack-set-channel)  ; チャンネル切替
;; C-u C-c S s で一度だけ送信先を上書き可能

