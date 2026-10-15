# Halo

Minimalistyczna powłoka graficzna (desktop shell) dla Linuksa, zbudowana na Hyprlandzie.
Motyw przewodni to świetlisty pierścień (aureola). Halo działa jako osobna sesja obok
KDE Plasma, wybierana na ekranie logowania. Pełny opis: [HALO_SPEC.md](HALO_SPEC.md).

**Stan: Etap 0.** Sesja „Halo” z tapetą, powiadomieniami i blokadą ekranu.
Pierścień (launcher) dojdzie w Etapie 1.

## Zależności

Zgodnie ze specyfikacją każda zależność ma uzasadnienie. Żadnych innych demonów, paneli ani usług w tle.

| Pakiet | Do czego | Uzasadnienie |
|---|---|---|
| `hyprland` | kompozytor | natywne zaokrąglenia, cienie i animacje, działa z NVIDIA; Halo ma **osobny** plik konfiguracyjny |
| `hyprpaper` | tapeta | najmniejsze narzędzie do tapety od twórców Hyprlanda |
| `hyprlock` | blokada ekranu | jw. |
| `mako` | powiadomienia | najmniejszy działający demon powiadomień |
| `wl-clipboard` | schowek | kalkulator kopiuje wynik (Etap 3) |
| `polkit-kde-agent` | okna haseł administratora | już zainstalowany z Plasmą, więc nie dochodzi nowy pakiet |
| `xdg-desktop-portal-hyprland` | portale | udostępnianie ekranu, skróty globalne; okno wyboru plików daje zainstalowany już `xdg-desktop-portal-gtk` |
| `quickshell` | launcher i ustawienia | potrzebny od Etapu 1 |
| `kitty` | terminal awaryjny (Super+Enter) | już zainstalowany |
| `libnotify` | `notify-send` do testu powiadomień | już zainstalowany |

Klawisze głośności i jasności używają `wpctl` i `brightnessctl`, które są już w systemie.
Aplikacje Qt/KDE (np. Dolphin) biorą motyw i ikony z ustawień Plasmy dzięki
`QT_QPA_PLATFORMTHEME=kde`. Wtyczka pochodzi z pakietu `plasma-integration`, który też jest już zainstalowany.
Fonty Geist i Geist Mono (sekcja 10 specyfikacji) są tylko w AUR (`otf-geist`, `otf-geist-mono`)
i są opcjonalne. Bez nich mako i hyprlock używają systemowego fontu bezszeryfowego (Noto Sans).

## Instalacja

Polecenia działają także w fish. Skrypty projektu same uruchamiają się w bashu.

**1. Ochrona powiadomień Plasmy (raz, przed instalacją mako).**

```bash
sudo sed -i '/^\[options\]/a NoExtract = usr/share/dbus-1/services/fr.emersion.mako.service' /etc/pacman.conf
```

Dlaczego: pakiet mako dodaje plik aktywacji D-Bus dla usługi powiadomień, a Plasma ma
własny plik dla tej samej usługi. dbus-broker wybiera pierwszy plik w kolejności
alfabetycznej, czyli plik mako. Przy każdym logowaniu do Plasmy jakiś program wysyła
powiadomienie, zanim Plasma przejmie tę usługę (widać to w `journalctl --user`), więc D-Bus
uruchomiłby mako w Plasmie i odebrał jej powiadomienia. Halo uruchamia mako samo, więc ten plik
jest zbędny. Linia `NoExtract` sprawia, że pacman go nie instaluje. Cofnięcie: usuń tę linię
z `/etc/pacman.conf`. Jeśli mako jest już zainstalowane, usuń też sam plik:

```bash
sudo rm /usr/share/dbus-1/services/fr.emersion.mako.service
```

**2. Brakujące pakiety.** `install.sh` pokazuje aktualną listę; na start było to:

```bash
sudo pacman -S --needed quickshell hyprpaper hyprlock mako
```

**3. Konfiguracja.** W katalogu repozytorium:

```bash
./install.sh
```

Skrypt tworzy symlinki `~/.config/halo/{hypr,mako,session,assets}` do katalogów repozytorium,
sprawdza konfigurację Hyprlanda i pyta o sudo **tylko** przy kopiowaniu pliku sesji do
`/usr/share/wayland-sessions/halo.desktop`. Można go uruchamiać wielokrotnie, np. po
przeniesieniu repozytorium. Nie dotyka `~/.config/hypr` ani konfiguracji Plasmy.

**4. Logowanie.** Wyloguj się, na ekranie logowania wybierz sesję „Halo” i zaloguj się.

## Jak to działa

- `session/halo.desktop` (kopiowany do `/usr/share/wayland-sessions/`) uruchamia
  `~/.config/halo/session/start-halo`.
- `start-halo` wykonuje `start-hyprland -- --config ~/.config/halo/hypr/hyprland.lua`.
  `start-hyprland` to zalecany od Hyprlanda 0.53 sposób startu. Pilnuje Hyprlanda i po awarii
  uruchamia go ponownie w trybie awaryjnym, z tymi samymi argumentami.
- Od Hyprlanda 0.55 konfiguracja jest w Lua (`hyprland.lua`), a stary format `.conf` jest przestarzały.
- `hyprland.lua` uruchamia hyprpaper, mako i agenta polkit, każdy z plikiem konfiguracyjnym z
  `~/.config/halo`. Domyślne `~/.config/hypr/hyprpaper.conf` i `~/.config/mako/config` nie są używane.

## Skróty

| Skrót | Działanie |
|---|---|
| Super+Enter | terminal (kitty) |
| Super+L | blokada ekranu |
| Super+Shift+E | wylogowanie (powrót do ekranu logowania) |
| Super+Q | zamknij okno |
| Super+F | pełny ekran (włącz/wyłącz) |
| Super+V | okno pływające / kafelkowe |
| Alt+Tab | następne okno |
| Super+strzałki | fokus w danym kierunku |
| Super+1…5 | pulpit 1–5 |
| Super+Shift+1…5 | przenieś okno na pulpit 1–5 |
| Super + lewy przycisk myszy | przesuwanie okna |
| Super + prawy przycisk myszy | zmiana rozmiaru okna |
| klawisze głośności i jasności | jak zwykle, działają też przy blokadzie |
| Alt+Spacja | pierścień Halo (od Etapu 1) |

## Awaryjny powrót do Plasmy

- **Normalnie:** Super+Shift+E, a na ekranie logowania wybierz „Plasma”.
- **Halo nie reaguje:** Ctrl+Alt+F3, zaloguj się w konsoli i wpisz `pkill -x start-hyprland`.
  Sesja Halo się zakończy. Ekran logowania jest zwykle pod Ctrl+Alt+F1 albo F2.
- **Blokada nie chce się odblokować:** Ctrl+Alt+F3, zaloguj się i wpisz `pkill -USR1 hyprlock`,
  potem wróć Ctrl+Alt+F1/F2.
- **Sesja nie startuje:** wracasz od razu do ekranu logowania. Powód znajdziesz w
  `~/.local/share/sddm/wayland-session.log`.

Halo nie zmienia `~/.config/hypr`, `~/.config/kde*` ani plików Plasmy. Poza katalogiem domowym
zmienia tylko `/usr/share/wayland-sessions/halo.desktop` i opcjonalnie dodaje linię `NoExtract`
w `/etc/pacman.conf`.

## Grafika hybrydowa (AMD + NVIDIA)

Sprawdzone na tym laptopie (zintegrowana AMD Phoenix + RTX 4060 Mobile, CachyOS, październik 2026):

- **Sterownik:** otwarte moduły NVIDIA dla jądra CachyOS, `nvidia-utils` i `egl-wayland`.
  Wszystko jest zainstalowane.
- **DRM KMS:** Wayland wymaga `nvidia_drm modeset=1` i `fbdev=1`. Pakiet `nvidia-utils` włącza
  je domyślnie (od wersji 560.35.03-5). Sprawdzenie: `cat /sys/module/nvidia_drm/parameters/modeset` ma pokazać `Y`.
- **Uśpienie:** od sterownika 595 pamięć VRAM przy uśpieniu zachowuje mechanizm
  „kernel suspend notifiers” (domyślnie od 615.78.08). Usługi `nvidia-suspend`,
  `nvidia-hibernate` i `nvidia-resume` mają więc zostać wyłączone. Sprawdzenie:
  `grep UseKernelSuspendNotifiers /proc/driver/nvidia/params` ma pokazać `1`.
- **Wybór GPU:** bez zmiennej `AQ_DRM_DEVICES` Hyprland używa wszystkich kart. Główną zostaje
  karta z wbudowanym ekranem (tu AMD), co wiki Hyprlanda zaleca dla laptopów ze względu na baterię.
  NVIDIA obsługuje swoje złącza: w tym laptopie HDMI jest podłączone do NVIDIA, więc zewnętrzny
  monitor działa przez nią. Dlatego Halo celowo nie ustawia `AQ_DRM_DEVICES`.
- **Bez zmiennych NVIDIA:** `LIBVA_DRIVER_NAME`, `__GLX_VENDOR_LIBRARY_NAME` i `GBM_BACKEND`
  przeniosłyby aplikacje na NVIDIA. Pojedynczy program uruchomisz na NVIDIA poleceniem
  `prime-run program`.
- **Wymuszenie kolejności kart** (tylko gdy coś nie działa, np. zewnętrzny monitor się nie
  pojawia): numery `/dev/dri/cardN` mogą się zmieniać przy starcie, a ścieżki z
  `/dev/dri/by-path` zawierają dwukropki, które w `AQ_DRM_DEVICES` są separatorem. Wiki zaleca
  regułę udev ze stałymi nazwami (opis: <https://wiki.hypr.land/Configuring/Extra/Multi-GPU/>),
  a potem w `hypr/hyprland.lua`:
  `hl.env("AQ_DRM_DEVICES", "/dev/dri/amd-igpu:/dev/dri/nvidia-dgpu")`.
  Adresy PCI w tym laptopie to AMD `0000:05:00.0` i NVIDIA `0000:01:00.0`.

## Diagnostyka

- Sprawdzenie konfiguracji bez uruchamiania sesji (robi to też `install.sh`):
  `Hyprland --verify-config --config ~/.config/halo/hypr/hyprland.lua`
- Log Hyprlanda: `$XDG_RUNTIME_DIR/hypr/*/hyprland.log`
- Log startu sesji: `~/.local/share/sddm/wayland-session.log`
- Monitory i karty: `hyprctl monitors`

## Odinstalowanie

```bash
sudo rm /usr/share/wayland-sessions/halo.desktop
```

```bash
rm -r ~/.config/halo
```

Drugie polecenie usuwa tylko symlinki, a repozytorium zostaje. Linię `NoExtract`
w `/etc/pacman.conf` możesz zostawić albo usunąć.

## Struktura

```
halo/
├── README.md
├── HALO_SPEC.md          # specyfikacja i etapy
├── LICENSE               # MIT
├── install.sh            # symlinki w ~/.config/halo, sudo tylko dla pliku sesji
├── session/
│   ├── halo.desktop      # wpis sesji dla ekranu logowania (szablon)
│   └── start-halo        # uruchamia Hyprlanda z konfiguracją Halo
├── hypr/
│   ├── hyprland.lua      # konfiguracja tylko dla sesji Halo
│   ├── hyprpaper.conf
│   └── hyprlock.conf
├── mako/
│   └── config
└── assets/
    ├── wallpaper.svg     # źródło tapety
    └── wallpaper.png     # tapeta (3840×2160)
```

## Licencja

MIT, zobacz [LICENSE](LICENSE).
