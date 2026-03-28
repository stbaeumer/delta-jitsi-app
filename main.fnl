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
(local state {:send-feedback nil
              :server-id nil
              :auto-reset (= (js.global.localStorage:getItem :auto-reset) :true)})

(local server-options
  [{:id "brie-fi" :label "brie.fi" :template "https://brie.fi/ng/$ROOM"}
   {:id "chitchatter" :label "chitchatter.im" :template "https://chitchatter.im/private/$ROOM"}
   {:id "galene" :label "galene.org" :template "https://galene.org:8443/group/public-vp9/$ROOM"}
   {:id "kmeet" :label "kmeet.infomaniak.com" :template "https://kmeet.infomaniak.com/$ROOM"}
   {:id "mirotalk-up" :label "mirotalk.up.railway.app" :template "https://mirotalk.up.railway.app/join/$ROOM"}
   {:id "mirotalk-p2p" :label "p2p.mirotalk.com" :template "https://p2p.mirotalk.com/join/$ROOM"}
   {:id "mirotalk-sfu" :label "sfu.mirotalk.com" :template "https://sfu.mirotalk.com/join/$ROOM"}
   {:id "systemli" :label "meet.systemli.org" :template "http://meet.systemli.org/$ROOM"}
   {:id "custom" :label "custom" :template ""}])

(local default-server-id (. (. server-options 1) :id))
(set state.server-id default-server-id)

;; Some handlers receive the element, others an event; normalize both cases.
(fn get-input-target [el-or-event]
  (or el-or-event.target el-or-event))

(fn trim-string [s]
  (if s
      (let [start (or (string.find s "%S") 1)
            rev   (string.reverse s)
            r-end (or (string.find rev "%S") 1)
            stop  (+ 1 (- (# s) r-end))]
        (if (< stop start) "" (string.sub s start stop)))
      ""))

(fn normalize-id [id]
  (if (= (type id) :string)
      id
      (let [raw (tostring id)]
        (if (= (string.sub raw 1 1) ":")
            (string.sub raw 2)
            raw))))

(fn get-field [id]
  (let [key (normalize-id id)]
    (or (. RV.id key)
        (. RV.id id)
        (document:getElementById key))))

(fn js-emptyish? [v]
  (or (= v nil)
      (= v js.null)
      (= v js.global.undefined)))

(fn input-value [id]
  (let [field (get-field id)]
    (if field
      (let [v (. field :value)]
        (if (js-emptyish? v)
            ""
            (tostring v)))
      "")))

(fn set-input-value [id value]
  (let [field (get-field id)]
    (when field
      (set (. field :value) value))))

(fn value-empty? [id]
  (= (trim-string (input-value id)) ""))

(fn selected-server-id []
  (or state.server-id default-server-id))

(fn find-server-option [server-id]
  (var found nil)
  (each [_ opt (ipairs server-options)]
    (if (= opt.id server-id)
        (set found opt)))
  found)

(fn selected-server-template []
  (let [server-id (selected-server-id)]
    (if (= server-id "custom")
        (trim-string (input-value :custom-server))
        (let [entry (find-server-option server-id)]
          (if entry
              entry.template
              (. (. server-options 1) :template))))))

(fn selected-server-label []
  (let [server-id (selected-server-id)]
    (if (= server-id "custom")
        (i18n.text :custom-server)
        (let [entry (find-server-option server-id)]
          (if entry
              entry.label
              (. (. server-options 1) :label))))))

(fn normalize-room-name [room]
  (let [trimmed (trim-string room)
        [normalized _] (string.gsub trimmed "%s+" "_")]
    normalized))

(fn strip-room-placeholder [template]
  (let [t (trim-string template)]
    (let [no-slash (string.gsub t "/%$ROOM" "")
          no-tag   (string.gsub no-slash "%$ROOM" "")]
      (trim-string no-tag))))

(fn join-base-and-room [base room]
  (let [clean-base (strip-room-placeholder base)]
    (if (or (= clean-base "") (= room ""))
        ""
        (if (string.find clean-base "/$")
            (.. clean-base room)
            (.. clean-base "/" room)))))

(fn server-with-room []
  (let [room     (normalize-room-name (input-value :room))
        template (trim-string (selected-server-template))]
    (if (or (= room "") (= template ""))
        ""
        (if (string.find template "%$ROOM")
            (let [[replaced _] (string.gsub template "%$ROOM" room)]
              replaced)
            (join-base-and-room template room)))))

(fn meeting-link []
  (let [room      (normalize-room-name (input-value :room))
        template  (trim-string (selected-server-template))
        room-safe (let [encoded (js.global.encodeURIComponent room)]
                    (if (or (= encoded nil)
                            (= encoded js.null)
                            (= encoded js.global.undefined)
                            (= encoded "undefined"))
                        room
                        encoded))]
    (if (or (= room "") (= template ""))
        ""
        (if (string.find template "%$ROOM")
            (let [[replaced _] (string.gsub template "%$ROOM" room-safe)]
              replaced)
            (join-base-and-room template room-safe)))))

;; This creates the header of the app
(render [:div {:class "container"}
         [:nav {}
          [:ul {}
           [:li {}
            [:div {:id "title"}
             [:b {} "🎥 Delta Jitsi Invite"]]]]]] "#nav")

;; Check if the input fields are filled or not.
(fn is-empty? [key]
  (or (= (?. RV.id key :value) nil) (= (?. RV.id key :value) "")))

;; Check if any required field is filled
(fn form-has-content? []
  (or (not (value-empty? :title))
      (not (value-empty? :description))
      (not (value-empty? :audience))
      (not (value-empty? :datetime))
      (not (value-empty? :duration))
      (not (value-empty? :agenda-link))
      (not (value-empty? :room))
  (not (value-empty? :custom-server))))

(fn form-valid? []
  (and (not (value-empty? :title))
       (not (value-empty? :description))
       (not (value-empty? :audience))
       (not (value-empty? :datetime))
       (not (value-empty? :duration))
       (not (value-empty? :room))
  (not= (meeting-link) "")
       (or (not= (selected-server-id) "custom")
           (not (value-empty? :custom-server)))))

;; Reset the form
(fn reset []
  (each [_ v (ipairs [:title :description :audience :datetime :duration :agenda-link :room :custom-server])]
    (if (not (is-empty? v))
        (set-input-value v "")))
  (set state.server-id default-server-id)
  (set-input-value :server default-server-id)
  (set state.send-feedback nil)
  (app.render))

;; Send chat message with icon.png attached so the conference context is visible at a glance.
(fn send-with-app-icon [text]
  (let [fallback-msg (js.new js.global.Object)]
    (set (. fallback-msg :text) text)
    (let [req (js.global.fetch "icon.png")]
  (let [p1 (req:then (fn [resp] (resp:blob)))
    p2 (p1:then (fn [blob]
          (let [msg (js.new js.global.Object)
            file-obj (js.new js.global.Object)]
            (set (. file-obj :name) "icon.png")
            (set (. file-obj :blob) blob)
            (set (. msg :text) text)
            (set (. msg :file) file-obj)
            (webxdc:sendToChat msg))))]
    (p2:catch (fn [_]
        (webxdc:sendToChat fallback-msg)))))))

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

;; When the user pastes/enters a full URL (e.g. https://meet.example.org/MyRoom)
;; without the $ROOM placeholder, extract the last path segment as room name,
;; replace it with $ROOM in the server field, and populate the room field.
(fn extract-and-apply-room-from-url []
  (let [url (trim-string (input-value :custom-server))]
    (when (and (not= url "") (not (string.find url "%$ROOM")))
      (let [(_ last-slash) (string.find url ".*/")
            (_ scheme-end) (string.find url "://")]
        (when last-slash
          ;; path-slash = first "/" after the scheme (i.e. after "://")
          ;; Ensures we don't mistake the scheme slashes for the path
          (let [path-slash (string.find url "/" (+ (or scheme-end 0) 1))]
            (when path-slash
              (let [room (string.sub url (+ last-slash 1))
                    base (string.sub url 1 (- last-slash 1))]
                (when (not= room "")
                  (set-input-value :custom-server (.. base "/$ROOM"))
                  (when (value-empty? :room)
                    (set-input-value :room room)))))))))))

(fn send-to-chat []
  (let [title         (trim-string (input-value :title))
        description   (trim-string (input-value :description))
        audience      (trim-string (input-value :audience))
        datetime      (if (value-empty? :datetime) "" (format-datetime (input-value :datetime)))
        duration      (trim-string (input-value :duration))
        agenda-link   (trim-string (input-value :agenda-link))
        room          (normalize-room-name (input-value :room))
        server-value  (server-with-room)
        join-link     (meeting-link)
        sections      [(.. "🎥 " title)
                       (.. "📝 " (i18n.text :description-field) ":\n" description)
                       (.. "👥 " (i18n.text :audience-field) ":\n" audience)
                       (.. "📅 " (i18n.text :datetime-field) ":\n" datetime)
                       (.. "⏱️ " (i18n.text :duration-field) ":\n" duration " " (i18n.text :minutes))
                       (.. "🖥️ " (i18n.text :server-field) ":\n" server-value)
                       (.. "🚪 " (i18n.text :room-field) ":\n" room)
                       (.. "🔗 " (i18n.text :join-link-field) ":\n" join-link)]
        meeting-text  (table.concat
                       (if (= agenda-link "")
                           sections
                           (let [with-agenda []]
                             (each [_ s (ipairs sections)]
                               (table.insert with-agenda s))
                             (table.insert with-agenda
                                           (.. "📎 " (i18n.text :agenda-link-field) ":\n" agenda-link))
                             with-agenda))
                       "\n\n")]
    (send-with-app-icon meeting-text)
    ;; Statusmeldung in der UI.
    (set state.send-feedback "✅ Gesendet.")
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

      ;; Audience
      [:label {:for "audience"}
       [:div {:class "label-icon"} icons.audience [:strong {} (i18n.text :audience-field)]]]
      (input-template :audience :audience-placeholder :audience-description)
      
      ;; Date and Time
      [:label {:for "datetime"}
       [:div {:class "label-icon"} icons.calendar [:strong {} (i18n.text :datetime-field)]]]
      [:div {}
       [:input {:id "datetime"
          :rvid "datetime"
          :type "datetime-local"
          :oninput (fn [el] (app.render))}]
       [:small {} (i18n.text :datetime-description)]]
      
      ;; Duration (minutes)
      [:label {:for "duration"}
       [:div {:class "label-icon"} icons.duration [:strong {} (i18n.text :duration-field)]]]
      [:div {}
       [:input {:id "duration"
          :rvid "duration"
          :type "number"
          :min "1"
                :oninput (fn [el] (app.render))}]
       [:small {} (i18n.text :duration-description)]]

      ;; Optional link upload
      [:label {:for "agenda-link"}
       [:div {:class "label-icon"} icons.url [:strong {} (i18n.text :agenda-link-field)]]]
      (input-template :agenda-link :agenda-link-placeholder :agenda-link-description)

      ;; Server dropdown
      [:label {:for "server"}
       [:div {:class "label-icon"} icons.server [:strong {} (i18n.text :server-field)]]]
      [:div {}
       [:select {:id "server"
           :rvid "server"
           :onchange (fn [el]
                       (let [target (get-input-target el)
                             server-val (trim-string (. target :value))]
                         (set state.server-id (if (= server-val "") default-server-id server-val))
                         ;; When switching back from custom to predefined server,
                         ;; clear stale custom URL to avoid preview confusion.
                         (when (not= state.server-id "custom")
                           (set-input-value :custom-server ""))
                         (app.render)))}
        (table.unpack
          (icollect [_ opt (ipairs server-options)]
            [:option {:value opt.id
                      :selected (if (= opt.id (selected-server-id)) "" nil)}
             (if (= opt.id "custom")
                 (i18n.text :custom-server)
               (strip-room-placeholder opt.template))]))]
       [:small {} (i18n.text :server-description)]]

      ;; Custom server input
      (if (= (selected-server-id) "custom")
        [:div {}
         [:label {:for "custom-server"}
        [:div {:class "label-icon"} icons.server [:strong {} (i18n.text :custom-server-field)]]]
         [:div {}
          [:input {:id "custom-server"
                   :rvid "custom-server"
                   :type "text"
                   :placeholder (i18n.text :custom-server-placeholder)
                   :oninput (fn [el] (app.render))
                   :onblur (fn [el]
                              (extract-and-apply-room-from-url)
                              (app.render))}]
          [:small {} (i18n.text :custom-server-description)]]]
        false)

      ;; Room name
      [:label {:for "room"}
       [:div {:class "label-icon"} icons.room [:strong {} (i18n.text :room-field)]]]
      [:div {}
       [:input {:id "room"
                :rvid "room"
                :type "text"
                :placeholder (i18n.text :room-placeholder)
                :oninput (fn [el]
                           (let [target (get-input-target el)]
                             (set (. target :value) (normalize-room-name (. target :value)))
                             (app.render)))}]
       [:small {} (i18n.text :room-description)]]
      
      ;; Preview
      (if (form-has-content?)
          [:article {}
           [:header {} (i18n.text :preview)]
         [:div {:class "conference-card"}
        [:div {:class "conference-header"}
         icons.conference
         [:h3 {} (if (value-empty? :title) (i18n.text :meeting-default-title) (input-value :title))]]
        (if (not (value-empty? :description))
          [:p {:class "conference-description"}
                 icons.description
           [:span {} (input-value :description)]])
        (if (not (value-empty? :audience))
          [:p {:class "conference-audience"}
           icons.audience
           [:span {} (input-value :audience)]])
        (if (not (value-empty? :datetime))
          [:p {:class "conference-datetime"}
                 icons.calendar
           [:span {} (format-datetime (input-value :datetime))]])
        (if (not (value-empty? :duration))
          [:p {:class "conference-duration"}
           icons.duration
           [:span {} (.. (input-value :duration) " " (i18n.text :minutes))]])
        (if (not= (selected-server-template) "")
          [:p {:class "conference-server"}
           icons.server
           [:span {} (server-with-room)]])
        (if (not (value-empty? :room))
          [:p {:class "conference-room"}
           icons.room
           [:span {} (input-value :room)]])
        (if (not= (meeting-link) "")
          [:p {:class "conference-url"}
           icons.url
           [:a {:href (meeting-link) :target "_blank"} (meeting-link)]])
        (if (not (value-empty? :agenda-link))
          [:p {:class "conference-agenda-link"}
           icons.attachment
           [:a {:href (input-value :agenda-link) :target "_blank"} (input-value :agenda-link)]])]]
          [:article {:class "example"}
           [:header {} (i18n.text :preview)]
         [:p {:style "color: var(--pico-muted-color)"} (i18n.text :preview-placeholder)]])
      
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
                :disabled (if (form-valid?) false true)
                :value (i18n.text :send) 
                :onclick send-to-chat}]
       [:input {:type "button" 
                :class "outline" 
                :value (i18n.text :reset) 
                :onclick reset 
                :disabled (if (form-has-content?) false true)}]]
      (if state.send-feedback
          [:p {:class "send-feedback"} state.send-feedback])]]
    ] "main"))

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
          [:p {} "Version 0.1.7"]
          [:hr {}]
          [:p {:class "license"} (i18n.text :anti-capitalist)]
          [:p {:class "license"} (i18n.text :open-source)]]] "#footer")
