(fn index [build]
  [:html {:lang "en"}
   [:head {}
    [:meta {:charset "UTF-8"}]
    [:meta {:name "viewport"
            :content "width=device-width, initial-scale=1.0"}]
    [:title {} "Found ICE"]

    ;; Add external assets
    (build.load-assets [["webxdc.js"                   :js  false ]
                        ["assets/pico.indigo.min.css"  :css false ]
                        ["style.css"                   :css false ]
                        ["libs/retrov.min.js"          :js  false ]])]
   
   [:body {}
    [:header {:id "nav"}]
    
    [:main {:class "container"}]

    [:footer {:class "container" :id "footer"}]]

   ;; Add external assets
   (build.load-assets [["libs/fengari-web.js"      :js  false ]
                       ["main.lua"                 :lua false ]])])

{ :html index }


