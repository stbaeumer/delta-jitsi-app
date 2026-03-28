(local i18n {})
(local js (require :js))
(local log (fn [...] (js.global.console:log ...)))

(set i18n.data 
     {
      ;; German - Default
      :de {:description [:div {}
                         [:p {} [:b {} "💳 Delta Wallet"] " ist eine App zum Erstellen und Teilen von Wallet-Einträgen. Speichere Tickets, Coupons, Mitgliedskarten und Zertifikate."]
                         [:p {} "Einfach die Informationen eingeben, ein schönes Wallet-Card-Format erhalten und direkt mit Freunden teilen!"]]
           :select-language "Sprache wählen"
           :language "Sprache"
           :open-source "Diese ist eine Open-Source-App"
           :anti-capitalist "Quelloffen und gemeinfrei"

           ;; Titles
           :title-field "Titel"
           :title-placeholder "z.B. Kinoticket"
           :title-description "Name oder Bezeichnung des Wallet-Eintrags"

           :description-field "Beschreibung"
           :description-placeholder "z.B. Filmtitel, Datum, Sitz"
           :description-description "Zusätzliche Details zum Eintrag"

           :url-field "URL"
           :url-placeholder "z.B. https://kino.de/ticket/12345"
           :url-description "Link zu mehr Informationen oder dem Ticket"

           :qrcode-field "QR-Code"
           :qrcode-placeholder ""
           :qrcode-description "PNG-Bild des QR-Codes hochladen (optional)"

           :datetime-field "Datum und Uhrzeit"
           :datetime-placeholder "z.B. 15. März 2025, 20:00 Uhr"
           :datetime-description "Wann ist dieser Eintrag relevant?"
           :now "Jetzt"

           :files-field "Dateien"
           :files-description "PDF, Bilder oder andere Dateien anhängen (optional)"

           :location-field "Treffpunkt"
           :location-placeholder "z.B. Hauptbahnhof Berlin, Gleis 7"
           :location-description "Wo findet der Termin statt? (optional)"

           :preview "Vorschau"
           :send "Senden"
           :reset "Zurücksetzen"
           :auto-reset "Formular nach dem Senden automatisch leeren"
           }
      ;; English
      :en {:description [:div {}
                         [:p {} [:b {} "💳 Delta Wallet"] " is an app for creating and sharing wallet entries. Store tickets, coupons, membership cards and certificates."]
                         [:p {} "Simply enter the information, get a beautiful wallet card format and share it directly with friends!"]]
           :select-language "Select language"
           :language "Language"
           :open-source "This is an open-source app"
           :anti-capitalist "Open source and public domain"

           ;; Titles
           :title-field "Title"
           :title-placeholder "e.g., Cinema Ticket"
           :title-description "Name or designation of the wallet entry"

           :description-field "Description"
           :description-placeholder "e.g., Movie title, date, seat"
           :description-description "Additional details about the entry"

           :url-field "URL"
           :url-placeholder "e.g., https://cinema.co.uk/ticket/12345"
           :url-description "Link for more information or the ticket"

           :qrcode-field "QR Code"
           :qrcode-placeholder ""
           :qrcode-description "Upload a PNG image of the QR code (optional)"

           :datetime-field "Date and Time"
           :datetime-placeholder "e.g., March 15, 2025, 8:00 PM"
           :datetime-description "When is this entry relevant?"
           :now "Now"

           :files-field "Files"
           :files-description "Attach PDFs, images or other files (optional)"

           :location-field "Location"
           :location-placeholder "e.g., Berlin Central Station, Platform 7"
           :location-description "Where does the appointment take place? (optional)"

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
