#!/usr/bin/env bash
# Halo — instalacja dla bieżącego użytkownika.
#   1. Sprawdza pakiety z sekcji 3 specyfikacji (niczego nie instaluje).
#   2. Ostrzega, jeśli mako mogłoby przejąć powiadomienia Plasmy.
#   3. Tworzy symlinki w ~/.config/halo do katalogów tego repozytorium.
#   4. Sprawdza konfigurację Hyprlanda.
#   5. Pyta o sudo TYLKO po to, by skopiować plik sesji do /usr/share/wayland-sessions.
# Nie dotyka ~/.config/hypr ani konfiguracji Plasmy. Można uruchamiać wielokrotnie.

set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
halo="$HOME/.config/halo"
sesja="/usr/share/wayland-sessions/halo.desktop"
bledy=0

naglowek() { printf '\n== %s\n' "$*"; }
ok()       { printf '  [ok] %s\n' "$*"; }
uwaga()    { printf '  [!]  %s\n' "$*"; }
info()     { printf '       %s\n' "$*"; }


naglowek "1. Pakiety"
# Format: pakiet:do czego służy
pakiety=(
    "hyprland:kompozytor"
    "hyprpaper:tapeta"
    "hyprlock:blokada ekranu"
    "mako:powiadomienia"
    "wl-clipboard:schowek"
    "polkit-kde-agent:okna haseł administratora (agent polkit z Plasmy)"
    "xdg-desktop-portal-hyprland:portale, np. udostępnianie ekranu"
    "quickshell:launcher (potrzebny od Etapu 1)"
    "kitty:terminal awaryjny (Super+Enter)"
    "libnotify:notify-send do testu powiadomień"
)
brak=()
for wpis in "${pakiety[@]}"; do
    nazwa="${wpis%%:*}"
    opis="${wpis#*:}"
    if pacman -Q "$nazwa" >/dev/null 2>&1; then
        ok "$nazwa — $opis"
    else
        uwaga "brak: $nazwa — $opis"
        brak+=("$nazwa")
    fi
done
if (( ${#brak[@]} > 0 )); then
    info ""
    info "Zainstaluj je sam (najpierw przeczytaj punkt 2):"
    info "  sudo pacman -S --needed ${brak[*]}"
fi


naglowek "2. Powiadomienia: mako a Plasma"
# Pakiet mako dodaje plik aktywacji D-Bus. Gdy jakiś program wyśle powiadomienie,
# zanim Plasma przejmie tę usługę (zdarza się przy logowaniu), D-Bus uruchomiłby
# mako w Plasmie. Halo uruchamia mako samo, więc ten plik nie jest potrzebny.
mako_dbus="usr/share/dbus-1/services/fr.emersion.mako.service"
plasma_dbus="/usr/share/dbus-1/services/org.kde.plasma.Notifications.service"
if ! grep -Eq "^[[:space:]]*NoExtract[[:space:]]*=.*fr\.emersion\.mako\.service" /etc/pacman.conf; then
    noextract=0
else
    noextract=1
fi
if [[ ! -e $plasma_dbus ]]; then
    ok "Plasma nie ma własnej usługi powiadomień — nic do zrobienia"
elif [[ -e /$mako_dbus ]]; then
    uwaga "/$mako_dbus może uruchomić mako w Plasmie."
    info "Napraw (wymaga sudo, opis w README):"
    (( noextract )) || info "  sudo sed -i '/^\[options\]/a NoExtract = $mako_dbus' /etc/pacman.conf"
    info "  sudo rm /$mako_dbus"
elif (( noextract )); then
    ok "pacman nie zainstaluje pliku aktywacji mako (NoExtract) — Plasma bezpieczna"
else
    uwaga "Zanim zainstalujesz mako, dodaj wyjątek do pacmana (wymaga sudo, opis w README):"
    info "  sudo sed -i '/^\[options\]/a NoExtract = $mako_dbus' /etc/pacman.conf"
fi


naglowek "3. Symlinki w $halo"
mkdir -p "$halo"
for kat in hypr mako session assets; do
    cel="$repo/$kat"
    link="$halo/$kat"
    if [[ -L $link ]]; then
        if [[ "$(readlink "$link")" == "$cel" ]]; then
            ok "$link"
        else
            # Stary lub zerwany symlink (np. po przeniesieniu repozytorium) — podmieniamy
            ln -sfn "$cel" "$link"
            ok "$link → $cel (poprawiony)"
        fi
    elif [[ -e $link ]]; then
        uwaga "$link istnieje i nie jest symlinkiem — nie ruszam. Przenieś go i uruchom skrypt ponownie."
        bledy=1
    else
        ln -s "$cel" "$link"
        ok "$link → $cel"
    fi
done


naglowek "4. Konfiguracja Hyprlanda"
if command -v Hyprland >/dev/null 2>&1; then
    if wynik="$(Hyprland --verify-config --config "$halo/hypr/hyprland.lua" 2>&1)"; then
        ok "$halo/hypr/hyprland.lua — bez błędów"
    else
        uwaga "Hyprland zgłasza błędy w konfiguracji:"
        printf '%s\n' "$wynik" | sed -n '/Config parsing result/,$p'
        bledy=1
    fi
else
    uwaga "Hyprland nie jest zainstalowany — pomijam sprawdzenie"
fi


naglowek "5. Plik sesji dla ekranu logowania"
start="$halo/session/start-halo"
# Ekran logowania nie poradzi sobie ze spacjami ani znakami specjalnymi w Exec=
if [[ ! $start =~ ^[A-Za-z0-9._/-]+$ ]]; then
    uwaga "Ścieżka $start zawiera znaki, których ekran logowania nie obsłuży."
    exit 1
fi
tymczasowy="$(mktemp)"
trap 'rm -f "$tymczasowy"' EXIT
sed "s|@START_HALO@|$start|" "$repo/session/halo.desktop" > "$tymczasowy"

if [[ -f $sesja ]] && cmp -s "$tymczasowy" "$sesja"; then
    ok "$sesja jest aktualny"
else
    info "Skrypt skopiuje plik sesji poleceniem:"
    info "  sudo install -m 644 <plik sesji Halo> $sesja"
    # Bez terminala (np. przekierowane wejście) odpowiedź to „nie”
    read -r -p "       Zrobić to teraz? [t/N] " odp || odp=""
    if [[ $odp == [tTyY] ]]; then
        sudo install -m 644 "$tymczasowy" "$sesja"
        ok "zainstalowano $sesja"
    else
        info "Pominięto. Uruchom install.sh ponownie, gdy zechcesz."
    fi
fi


naglowek "Gotowe"
info "Test: wyloguj się, na ekranie logowania wybierz sesję „Halo” i zaloguj się."
info "Powrót: Super+Shift+E (wylogowanie), potem wybierz „Plasma”."
exit "$bledy"
