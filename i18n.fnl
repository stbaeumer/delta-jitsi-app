(local i18n {})
(local js (require :js))
(local log (fn [...] (js.global.console:log ...)))

(set i18n.data 
     {
      ;; German - Default
      :de {:description [:div {}
          [:p {} [:b {} "🎥 Delta Jitsi Invite"] " ist eine App zum Erstellen und Teilen von Einladungen zu Videokonferenzen."]
          [:p {} "Trage die Konferenzdaten ein, erzeuge einen Beitrittslink und teile die Einladung direkt im Chat."]]
           :select-language "Sprache wählen"
           :language "Sprache"
           :open-source "Diese ist eine Open-Source-App"
           :anti-capitalist "Quelloffen und gemeinfrei"

           ;; Titles
           :title-field "Titel"
     :title-placeholder "z.B. Team-Weekly"
     :title-description "Titel der Konferenz"

           :description-field "Beschreibung"
     :description-placeholder "z.B. Themen, Ziele, Ablauf"
     :description-description "Kurze Beschreibung der Konferenz"

     :audience-field "Zielgruppe"
     :audience-placeholder "z.B. Projektteam, Kund:innen, Vorstand"
     :audience-description "Für wen ist die Konferenz gedacht?"

     :meeting-file-field "Einladung / Agenda (Datei)"
     :meeting-file-description "Optionale Datei hochladen (z.B. PDF, Bild, Dokument)"

     :agenda-link-field "Einladung / Agenda (Link)"
     :agenda-link-placeholder "z.B. https://example.org/agenda"
     :agenda-link-description "Optionaler Link zu Einladung, Agenda oder Unterlagen"

           :datetime-field "Datum und Uhrzeit"
     :datetime-description "Wann startet die Konferenz?"

     :duration-field "Dauer in Minuten"
     :duration-description "Geplante Dauer der Konferenz"
     :minutes "Minuten"

     :server-field "Server"
     :server-description "Wähle einen vordefinierten Server oder nutze einen eigenen"
     :custom-server "Anderer Server"
     :custom-server-field "Eigener Server-URL"
     :custom-server-placeholder "z.B. https://meet.example.org/$ROOM"
     :custom-server-description "Server-URL mit oder ohne $ROOM-Platzhalter"

     :room-field "Raumname"
     :room-placeholder "z.B. projekt-standup"
     :room-description "Individueller Name des Konferenzraums"

     :meeting-default-title "Konferenz"
     :preview-placeholder "Konferenz-Vorschau erscheint hier..."

           :files-field "Dateien"
           :files-description "PDF, Bilder oder andere Dateien anhängen (optional)"

           :preview "Vorschau"
           :send "Senden"
           :reset "Zurücksetzen"
           :auto-reset "Formular nach dem Senden automatisch leeren"
           }
      ;; English
      :en {:description [:div {}
          [:p {} [:b {} "🎥 Delta Jitsi Invite"] " is an app for creating and sharing video conference invitations."]
          [:p {} "Enter your conference details, generate a join link and share the invite directly in chat."]]
           :select-language "Select language"
           :language "Language"
           :open-source "This is an open-source app"
           :anti-capitalist "Open source and public domain"

           ;; Titles
           :title-field "Title"
     :title-placeholder "e.g., Team Weekly"
     :title-description "Conference title"

           :description-field "Description"
     :description-placeholder "e.g., topics, goals, agenda"
     :description-description "Short conference description"

     :audience-field "Audience"
     :audience-placeholder "e.g., project team, customers, board"
     :audience-description "Who is this conference for?"

     :meeting-file-field "Invitation / Agenda (file)"
     :meeting-file-description "Optional file upload (e.g., PDF, image, document)"

     :agenda-link-field "Invitation / Agenda (link)"
     :agenda-link-placeholder "e.g., https://example.org/agenda"
     :agenda-link-description "Optional link to invitation, agenda or documents"

           :datetime-field "Date and Time"
     :datetime-description "When does the conference start?"

     :duration-field "Duration in minutes"
     :duration-description "Planned conference duration"
     :minutes "minutes"

     :server-field "Server"
     :server-description "Choose a predefined server or use your own"
     :custom-server "Other server"
     :custom-server-field "Custom server URL"
     :custom-server-placeholder "e.g., https://meet.example.org/$ROOM"
     :custom-server-description "Server URL with or without $ROOM placeholder"

     :room-field "Room name"
     :room-placeholder "e.g., project-standup"
     :room-description "Individual name of the conference room"

     :meeting-default-title "Conference"
     :preview-placeholder "Conference preview appears here..."

           :files-field "Files"
           :files-description "Attach PDFs, images or other files (optional)"

           :preview "Preview"
           :send "Send"
           :reset "Reset"
           :auto-reset "Clear form automatically after sending"
           }
      })

(fn lang-apply [lang dir]
  (let [html-el (js.global.document:querySelector "html")]
    (set i18n.locale lang)
    (html-el:setAttribute :lang lang)
    (html-el:setAttribute :dir dir)))

(fn i18n.setLang [el]
  (log "Changed language" el.value)
  (js.global.localStorage:setItem :lang el.value)
  (js.global.location:reload))

(fn i18n.text [key]
  (let [text (. i18n.data i18n.locale key)]
    ;; Return the text itself otherwise fallback to English
    (if (not= text nil)
        text
        (. i18n.data :en key))))

(fn checkLang []
  ;; Default is German (Deutsch)
  (var found :de)
  ;; If the user agent prefers a different language, we switch to that
  (each [_ lang (ipairs [:de :en])]
    (if (string.match js.global.navigator.language (.. "^" lang))
        (set found lang))) 
  found)

(let [saved (js.global.localStorage:getItem :lang)
      lang  (if (= saved js.null) (checkLang) saved)]
  (case lang
    :de    (lang-apply lang :ltr)
    :en    (lang-apply lang :ltr)))

i18n
