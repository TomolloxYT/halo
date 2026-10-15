-- Halo — konfiguracja Hyprlanda TYLKO dla sesji Halo.
-- Ładuje ją session/start-halo poleceniem: start-hyprland -- --config <ten plik>.
-- Twoja zwykła konfiguracja z ~/.config/hypr nie jest tu używana ani zmieniana.
-- Składnia: Lua (Hyprland 0.55+), dokumentacja: https://wiki.hypr.land/Configuring/
-- Sprawdzenie bez uruchamiania sesji:
--   Hyprland --verify-config --config ~/.config/halo/hypr/hyprland.lua

-- Katalog Halo (symlinki do repozytorium tworzy install.sh)
local halo = os.getenv("HOME") .. "/.config/halo"

-- Terminal awaryjny (Super+Enter)
local terminal = "kitty"


---------------
-- MONITORY ---
---------------

-- Każdy monitor (także zewnętrzny): najlepsza rozdzielczość, automatyczne położenie i skala
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = "auto",
})


-----------------------------
-- GRAFIKA HYBRYDOWA (NVIDIA)
-----------------------------

-- Nic nie ustawiamy celowo. Bez AQ_DRM_DEVICES Hyprland używa wszystkich kart:
-- rysuje na tej z wbudowanym ekranem (AMD, oszczędza baterię), a NVIDIA
-- obsługuje swoje złącza (HDMI). Kolejność kart wymusza się tylko w razie
-- problemów — opis w README, sekcja „Grafika hybrydowa”.
-- Zmiennych LIBVA_DRIVER_NAME / __GLX_VENDOR_LIBRARY_NAME nie ustawiamy,
-- bo przeniosłyby wszystkie aplikacje na NVIDIA. Pojedynczy program na NVIDIA:
-- prime-run <program>.


-------------------------
-- ZMIENNE ŚRODOWISKOWE --
-------------------------

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
-- Aplikacje Qt/KDE (np. Dolphin) biorą motyw i ikony z ustawień Plasmy (tylko odczyt)
hl.env("QT_QPA_PLATFORMTHEME", "kde")


---------------
-- AUTOSTART --
---------------

-- Tylko to, czego wymaga specyfikacja (sekcja 5). Żadnych innych usług w tle.
hl.on("hyprland.start", function()
    hl.exec_cmd("hyprpaper --config '" .. halo .. "/hypr/hyprpaper.conf'")   -- tapeta
    hl.exec_cmd("mako --config '" .. halo .. "/mako/config'")                -- powiadomienia
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")                -- okna haseł administratora
end)


------------
-- WYGLĄD --
------------

-- Kolory z sekcji 10 specyfikacji (format rgba(RRGGBBAA))
hl.config({
    general = {
        gaps_in     = 5,
        gaps_out    = 10,
        border_size = 2,
        col = {
            active_border   = "rgba(f4d58db3)",  -- akcent, krycie 70%
            inactive_border = "rgba(ffffff1a)",  -- linia, krycie 10%
        },
        layout = "dwindle",
    },

    decoration = {
        rounding = 12,
        shadow = {
            enabled      = true,
            range        = 16,
            render_power = 3,
            color        = "rgba(00000066)",
        },
        -- Bez rozmycia: prościej i lżej dla GPU
        blur = { enabled = false },
    },

    animations = { enabled = true },

    input = {
        kb_layout    = "pl",
        follow_mouse = 1,
    },

    misc = {
        -- Zamiast logo Hyprlanda: tło Halo (widoczne, zanim hyprpaper narysuje tapetę)
        disable_hyprland_logo    = true,
        disable_splash_rendering = true,
        force_default_wallpaper  = 0,
        background_color         = "rgb(0e1013)",
        -- Jeśli hyprlock się zawiesi, można go uruchomić ponownie (zamiast czerwonego ekranu)
        allow_session_lock_restore = true,
    },

    -- Bez okna „co nowego” po aktualizacji Hyprlanda
    ecosystem = { no_update_news = true },
})


------------
-- SKRÓTY --
------------

local mod = "SUPER"

-- Alt+Spacja: pierścień Halo — dojdzie w Etapie 1 (Quickshell)

-- Blokada ekranu (pidof: nie uruchamiaj drugiej kopii)
hl.bind(mod .. " + L", hl.dsp.exec_cmd("pidof hyprlock || hyprlock --config '" .. halo .. "/hypr/hyprlock.conf'"))

-- Terminal awaryjny
hl.bind(mod .. " + Return", hl.dsp.exec_cmd(terminal))

-- Wylogowanie: hyprshutdown (jeśli jest) łagodnie zamyka programy, inaczej zwykłe wyjście
hl.bind(mod .. " + SHIFT + E", hl.dsp.exec_cmd("command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"))

-- Okna
hl.bind(mod .. " + Q", hl.dsp.window.close())                       -- zamknij
hl.bind(mod .. " + F", hl.dsp.window.fullscreen())                  -- pełny ekran (przełącz)
hl.bind(mod .. " + V", hl.dsp.window.float({ action = "toggle" }))  -- pływające / kafelkowe

-- Alt+Tab: następne okno i wyciągnięcie go na wierzch
hl.bind("ALT + Tab", function()
    hl.dispatch(hl.dsp.window.cycle_next())
    hl.dispatch(hl.dsp.window.bring_to_top())
end)

-- Super+strzałki: fokus w danym kierunku
for _, kierunek in ipairs({ "left", "right", "up", "down" }) do
    hl.bind(mod .. " + " .. kierunek, hl.dsp.focus({ direction = kierunek }))
end

-- Super+1…5: pulpit; Super+Shift+1…5: przenieś okno na pulpit
for i = 1, 5 do
    hl.bind(mod .. " + " .. i,            hl.dsp.focus({ workspace = i }))
    hl.bind(mod .. " + SHIFT + " .. i,    hl.dsp.window.move({ workspace = i }))
end

-- Super + lewy przycisk myszy: przesuwanie; Super + prawy: zmiana rozmiaru
hl.bind(mod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Klawisze głośności i jasności (wpctl i brightnessctl są już w systemie).
-- locked: działają też przy zablokowanym ekranie.
hl.bind("XF86AudioRaiseVolume",  hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume",  hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",         hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),     { locked = true })
hl.bind("XF86AudioMicMute",      hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                  { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                  { locked = true, repeating = true })
