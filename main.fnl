;; JS interop
(local {:global { : document
                  : navigator
                  : webxdc } &as js} (require :js))
(local log (fn [...] (js.global.console:log ...)))

;; HTML library
(local { : render
         : RV } (require :html))

;; Internationalization
(local i18n (require :i18n))

;; Add icons
(local icons (require :icons))

(local app {})
;; auto-reset preference is persisted in localStorage
(local state {:qrcode-data nil :qrcode-file nil :send-feedback nil
              :auto-reset (= (js.global.localStorage:getItem :auto-reset) :true)})

;; Some handlers receive the element, others an event; normalize both cases.
(fn get-input-target [el-or-event]
  (or el-or-event.target el-or-event))

;; This creates the header of the app
(render [:div {:class "container"}
         [:nav {}
          [:ul {}
           [:li {}
            [:div {:id "title"}
             [:b {} "💳 Delta Wallet"]]]]]] "#nav")

;; Check if the input fields are filled or not.
(fn is-empty? [key]
  (or (= (?. RV.id key :value) nil) (= (?. RV.id key :value) "")))

;; Check if any required field is filled
(fn form-has-content? []
  (or (not (is-empty? :title))
      (not (is-empty? :description))
      (not (is-empty? :url))
      (not= state.qrcode-data nil)
      (not (is-empty? :datetime))
      (not (is-empty? :location))))

;; Reset the form
(fn reset []
  (each [_ v (ipairs [:title :description :url :datetime :location])]
    (if (not (is-empty? v))
        (set (. RV.id v :value) "")))
  (set state.qrcode-data nil)
  (set state.qrcode-file nil)
  (set state.send-feedback nil)
  (app.render))

;; Read a QR-Code image file and store as data URL
(fn read-qr-code [el]
  (let [target (get-input-target el)
        file   (. target.files 0)]
    (if file
        (do
          (set state.qrcode-file file)
          (let [reader (js.new js.global.FileReader)]
            (set reader.onload (fn [ev]
                                 (set state.qrcode-data (or (?. ev :target :result)
                                                             reader.result))
                                 (app.render)))
            (reader:readAsDataURL file)))
        (do
          (set state.qrcode-file nil)
          (set state.qrcode-data nil)
          (app.render)))))

;; Format a datetime-local value (YYYY-MM-DDThh:mm) in locale-aware form
(fn format-datetime [iso-str]
  (let [year  (string.match iso-str "^(%d%d%d%d)")
        month (string.match iso-str "^%d%d%d%d%-(%d%d)")
        day   (string.match iso-str "^%d%d%d%d%-%d%d%-(%d%d)")
        time  (string.match iso-str "T(%d%d:%d%d)")]
    (if (and year month day)
        (let [month-num (tonumber month)
              day-num   (tonumber day)]
          (if (= i18n.locale :de)
              (let [months ["Januar" "Februar" "März" "April" "Mai" "Juni"
                            "Juli" "August" "September" "Oktober" "November" "Dezember"]]
                (.. day-num ". " (. months month-num) " " year
                    (if time (.. ", " time " Uhr") "")))
              (let [months ["January" "February" "March" "April" "May" "June"
                            "July" "August" "September" "October" "November" "December"]]
                (.. (. months month-num) " " day-num ", " year
                    (if time (.. ", " time) "")))))
        iso-str)))

(fn input-template [id placeholder-key description-key]
  [:div {}
   [:input {:id id
            :rvid id
            :type "text"
            :placeholder (i18n.text placeholder-key)
            :oninput (fn [el] (app.render))}]
   [:small {} (i18n.text description-key)]])

(fn textarea-template [id placeholder-key description-key]
  [:div {}
   [:textarea {:id id
               :rvid id
               :placeholder (i18n.text placeholder-key)
               :oninput (fn [el] (app.render))}]
   [:small {} (i18n.text description-key)]])

(fn send-to-chat []
  (let [title       (if (is-empty? :title) "Wallet Entry" RV.id.title.value)
        description (if (is-empty? :description) "" RV.id.description.value)
        url         (if (is-empty? :url) "" RV.id.url.value)
        datetime    (if (is-empty? :datetime) "" (format-datetime RV.id.datetime.value))
        location    (if (is-empty? :location) "" RV.id.location.value)
        wallet-text (.. "💳 " title
                        (if (= description "") "" (.. "\n\n📝 " description))
                        (if (= url "") "" (.. "\n\n🔗 " url))
                        (if (= datetime "") "" (.. "\n\n📅 " datetime))
                        (if (= location "") "" (.. "\n\n📍 " location)))]
    ;; Wallet-Nachricht: Text + QR-Code-Bild in EINER Nachricht.
    (let [main-obj (js.new js.global.Object)]
      (set (. main-obj :text) wallet-text)
      (when state.qrcode-file
        (let [qr-file-obj (js.new js.global.Object)]
          (set (. qr-file-obj :name) (or state.qrcode-file.name "qrcode.png"))
          (set (. qr-file-obj :blob) state.qrcode-file)
          (set (. main-obj :file) qr-file-obj)))
      (webxdc:sendToChat main-obj))
    ;; Statusmeldung in der UI.
    (set state.send-feedback
         (.. "✅ Gesendet"
             (if state.qrcode-file " · QR-Code angehängt" "")
             "."))
    (if state.auto-reset
        (reset)
        (app.render))))

;; Render function for rendering the whole page
(fn app.render []
  (render
   [:div {}
    [:form {}
     [:fieldset {}
      
      ;; Title
      [:label {:for "title"} 
       [:div {:class "label-icon"} icons.title [:strong {} (i18n.text :title-field)]]]
      (input-template :title :title-placeholder :title-description)

      ;; Description
      [:label {:for "description"} 
       [:div {:class "label-icon"} icons.description [:strong {} (i18n.text :description-field)]]]
      (textarea-template :description :description-placeholder :description-description)
      
      ;; URL
      [:label {:for "url"} 
       [:div {:class "label-icon"} icons.url [:strong {} (i18n.text :url-field)]]]
      (input-template :url :url-placeholder :url-description)
      
      ;; QR-Code - Bild hochladen
      [:label {:for "qrcode"} 
       [:div {:class "label-icon"} icons.qrcode [:strong {} (i18n.text :qrcode-field)]]]
      [:div {}
       [:input {:id "qrcode"
                :type "file"
                :accept "image/png"
                :onchange read-qr-code}]
       [:small {} (i18n.text :qrcode-description)]]
      
      ;; Date and Time
      [:label {:for "datetime"} 
       [:div {:class "label-icon"} icons.calendar [:strong {} (i18n.text :datetime-field)]]]
      [:div {}
       [:input {:id "datetime"
                :rvid "datetime"
                :type "datetime-local"
                :oninput (fn [el] (app.render))}]
       [:small {} (i18n.text :datetime-description)]]
      
      ;; Treffpunkt (optional)
      [:label {:for "location"}
       [:div {:class "label-icon"} icons.location [:strong {} (i18n.text :location-field)]]]
      (input-template :location :location-placeholder :location-description)

      ;; Preview
      (if (form-has-content?)
          [:article {}
           [:header {} (i18n.text :preview)]
           [:div {:class "wallet-card"}
            [:div {:class "wallet-header"}
             icons.wallet
             [:h3 {} (if (is-empty? :title) "Wallet Entry" RV.id.title.value)]]
            (if (not (is-empty? :description))
                [:p {:class "wallet-description"} 
                 icons.description
                 [:span {} RV.id.description.value]])
            (if (not (is-empty? :url))
                [:p {:class "wallet-url"} 
                 icons.url 
                 [:a {:href RV.id.url.value :target "_blank"} RV.id.url.value]])
            (if (not= state.qrcode-data nil)
                [:p {:class "wallet-qrcode"}
                 icons.qrcode
                 [:img {:src state.qrcode-data :alt "QR Code" :style "max-width: 150px; max-height: 150px;"}]])
            (if (not (is-empty? :datetime))
                [:p {:class "wallet-datetime"}
                 icons.calendar
                 [:span {} (format-datetime RV.id.datetime.value)]])
            (if (not (is-empty? :location))
                [:p {:class "wallet-location"}
                 icons.location
                 [:span {} RV.id.location.value]])]]
          [:article {:class "example"}
           [:header {} (i18n.text :preview)]
           [:p {:style "color: var(--pico-muted-color)"} "Wallet-Vorschau erscheint hier..."]])
      
      ;; Auto-reset checkbox
      [:label {:class "auto-reset-label"}
       [:input {:id "auto-reset"
                :type "checkbox"
                :checked state.auto-reset
                :onchange (fn [el]
                            (let [target (get-input-target el)]
                              (set state.auto-reset target.checked)
                              (js.global.localStorage:setItem :auto-reset
                                (if target.checked :true :false))
                              (app.render)))}]
       (i18n.text :auto-reset)]

      ;; Buttons
      [:div {:class "button-group"}
       [:input {:type "button" 
                :class "primary" 
                :disabled (if (form-has-content?) false true) 
                :value (i18n.text :send) 
                :onclick send-to-chat}]
       [:input {:type "button" 
                :class "outline" 
                :value (i18n.text :reset) 
                :onclick reset 
                :disabled (if (form-has-content?) false true)}]]
      (if state.send-feedback
          [:p {:class "send-feedback"} state.send-feedback])]]
    ]"main"))

(app.render)

;; The footer is in here instead of index.fnl because we want the text to
;; change based on the language of the app.
(render [:div {} 
         (i18n.text :description)
         [:select {:name "select" :ariaLabel (i18n.text :select-language) :onchange i18n.setLang}
          [:option {:selected "" :value "" :disabled ""} (i18n.text :language)]
          [:option {:value "de"} "Deutsch"]
          [:option {:value "en"} "English"]]
         [:div {:id "version"}
          [:hr {}]
          [:p {} "Version 0.0.11"]
          [:hr {}]
          [:p {:class "license"} (i18n.text :anti-capitalist)]
          [:p {:class "license"} (i18n.text :open-source)]]] "#footer")
