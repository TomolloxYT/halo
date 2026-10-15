# Halo — specyfikacja dla Claude Code

Halo to minimalistyczna powłoka graficzna (desktop shell) dla Linuksa. Nazwa pochodzi od aureoli, a motywem przewodnim jest świetlisty pierścień.

## 1. Cel

Funkcjonalna, mocno odchudzona sesja graficzna do codziennego użytku, bez zbędnych usług w tle. Na początku działa jako osobna sesja obok KDE Plasma, wybierana na ekranie logowania. Docelowo ma zastąpić Plasmę.

**Zasada nadrzędna:** każdy etap kończy się czymś, co działa i da się przetestować. Mniej funkcji, ale działających.

## 2. Środowisko docelowe

- **System:** CachyOS (Arch). KDE Plasma jest zainstalowana i **musi dalej działać bez zmian**.
- **Sprzęt:** laptop z grafiką hybrydową AMD + NVIDIA (RTX 4060), czasem podłączany zewnętrzny monitor.
- **Powłoka użytkownika:** fish. Skrypty projektu zaczynają się od `#!/usr/bin/env bash` i nie zakładają bash w terminalu.
- **Czas:** około 3 godzin tygodniowo, dlatego etapy są małe.
- **Autor:** testuje i uczy się QML, ale sam nie pisze kodu. Kod ma być czytelny, z krótkimi komentarzami po polsku.

## 3. Architektura

| Warstwa | Wybór | Dlaczego |
|---|---|---|
| Kompozytor | Hyprland z **osobnym** plikiem konfiguracyjnym sesji Halo | Natywne zaokrąglenia, cienie i animacje, działa z NVIDIA |
| Launcher i ustawienia | Quickshell (QML) | Lekki, zrobiony pod Hyprland |
| Tapeta | hyprpaper | |
| Blokada ekranu | hyprlock | |
| Powiadomienia | mako w kolorach Halo | Najmniejszy działający demon; później można przenieść do Quickshell |
| Schowek | wl-clipboard | Kalkulator kopiuje wynik |
| Niezbędne minimum | agent polkit, xdg-desktop-portal-hyprland | Bez nich część aplikacji nie działa (hasła administratora, okna wyboru plików) |

**Zasada odchudzenia:** żadnych innych demonów, paneli, docków ani usług w tle. Każda nowa zależność wymaga uzasadnienia w README.

## 4. Struktura repozytorium

```
halo/
├── README.md
├── HALO_SPEC.md
├── LICENSE              # licencję wybiera autor (np. MIT lub GPL-3.0)
├── install.sh           # tworzy symlinki w ~/.config/halo, pyta o sudo tylko dla pliku sesji
├── session/
│   ├── halo.desktop     # wpis sesji dla ekranu logowania
│   └── start-halo       # uruchamia Hyprland z konfiguracją Halo
├── hypr/
│   ├── hyprland.lua     # konfiguracja tylko dla sesji Halo (od Hyprlanda 0.55 w Lua)
│   ├── hyprpaper.conf
│   └── hyprlock.conf
├── mako/
│   └── config
├── assets/              # tapeta (wallpaper.svg → wallpaper.png)
└── shell/               # konfiguracja Quickshell
    ├── shell.qml
    ├── theme/Theme.qml  # tokeny z sekcji 10
    ├── launcher/        # pierścień, wyszukiwanie, dostawcy wyników
    ├── settings/        # okno Ustawień Halo
    ├── calc/            # parser kalkulatora + testy
    └── i18n/            # pl.json, en.json
```

## 5. Sesja Halo

- **Plik sesji:** `session/halo.desktop` trafia do `/usr/share/wayland-sessions/`. To wymaga sudo, więc skrypt pokazuje komendę i pyta.
- **Konfiguracja Hyprlanda:** sesja uruchamia Hyprland z konfiguracją z repo (przez `~/.config/halo/`), **nie** z `~/.config/hypr/`. Istniejąca konfiguracja Hyprlanda autora zostaje nietknięta.
- **Autostart:** hyprpaper, mako, agent polkit, Quickshell z konfiguracją Halo.
- **Skróty:**
  - Alt+Spacja: pierścień.
  - Super+L: blokada.
  - Super+Enter: terminal (awaryjnie).
  - Super+Shift+E: wylogowanie.
  - Kilka podstawowych skrótów okien (zamknij, pełny ekran, przełączanie), opisanych w README.
- **Awaryjne wyjście:** wylogowanie zawsze wraca do ekranu logowania, gdzie można wybrać Plasmę.
- **Alt+Spacja:** w Plasmie ten skrót otwiera KRunner, ale w sesji Halo nie ma konfliktu.

## 6. Launcher: pierścień (najważniejsza część v1)

### Zachowanie

- **Otwieranie:** Alt+Spacja otwiera i zamyka launcher.
- **Monitor:** pierścień pojawia się na **monitorze, na którym jest kursor**, wyśrodkowany na tym monitorze.
- **Kursor:** po otwarciu kursor przeskakuje na **środek pierścienia**.
- **Klawiatura:** pole wyszukiwania od razu ma fokus, więc można pisać bez klikania.
- **Zamykanie:** Esc, kliknięcie poza pierścieniem albo ponowne Alt+Spacja.
- **Uruchomienie** aplikacji zamyka launcher.
- **Tło:** przyciemnienie całego monitora, bez rozmycia w v1.

### Pierścień

- **Liczba aplikacji:** od 4 do 12, z konfiguracji, rozłożone równo na okręgu. Pierwsza jest na górze, kolejne idą zgodnie z ruchem wskazówek zegara.
- **Mysz:** kliknięcie uruchamia aplikację, najechanie ją zaznacza.
- **Klawiatura:** strzałki ←/→ oraz Tab i Shift+Tab przesuwają zaznaczenie po okręgu, Enter uruchamia.
- **Podpis:** nazwa zaznaczonej aplikacji jest pod polem wyszukiwania.

### Wyszukiwanie (v1: aplikacje i kalkulator)

- **Aplikacje:** pisanie filtruje zainstalowane aplikacje z plików `.desktop`.
  - Dopasowuje po nazwie, nazwie ogólnej i słowach kluczowych.
  - Ignoruje wielkość liter i polskie znaki (ą = a).
  - Wyniki zastępują ikony na pierścieniu, tyle ile jest miejsc. Pierwszy wynik jest zaznaczony, Enter go uruchamia.
  - Bez wyników środek pokazuje „Brak wyników” / „No results”.
- **Kalkulator:** gdy wpis jest wyrażeniem matematycznym, środek pokazuje `= wynik`.
  - Obsługuje cyfry, `+ - * / ^ %`, nawiasy oraz przecinek i kropkę dziesiętną.
  - Enter kopiuje wynik do schowka (`wl-copy`) i zamyka launcher.
  - **Własny mały parser.** Nie używać `eval` ani `Function` na tekście użytkownika.
- **Miejsce na przyszłość:**
  - Wpis zaczynający się od `;` to komenda. W v1 pokazuje tylko „Komendy wkrótce” / „Commands coming soon”.
  - Wyszukiwanie jest podzielone na **dostawców** (`apps`, `calc`). Pliki, internet i komendy dojdą jako nowi dostawcy, bez przebudowy launchera.

### Animacja

- **Otwarcie:** krycie 0 → 1 i skala 0,96 → 1, około 150 ms, łagodne wyhamowanie.
- **Zamknięcie:** około 100 ms.
- Żadnych innych efektów.

## 7. Okno Ustawień Halo

- **Otwieranie:** osobne okno, uruchamiane wpisem „Ustawienia Halo” w wyszukiwarce launchera (przez IPC Quickshell albo plik `.desktop`).
- **Funkcje v1:**
  - Lista aplikacji na pierścieniu (od 4 do 12):
    - dodawanie z listy zainstalowanych, z wyszukiwaniem;
    - usuwanie;
    - zmiana kolejności przyciskami w górę i w dół (przeciąganie opcjonalnie);
    - zmiana ikony: nazwa ikony z **motywu systemu** albo **własny plik PNG/SVG**.
  - Podgląd pierścienia na żywo.
  - Język: Polski / English.
  - Przycisk „Przywróć domyślne”.
- **Zapis:** do `~/.config/halo/config.json`. Launcher wczytuje zmiany bez restartu sesji.
- **Walidacja:** minimum 4 i maksimum 12 aplikacji. Gdy ikony brakuje, pojawia się ikona zastępcza.

## 8. Plik konfiguracyjny

```json
{
  "version": 1,
  "language": "pl",
  "accent": "#F4D58D",
  "ring": [
    { "desktopId": "kitty.desktop", "icon": null },
    { "desktopId": "org.kde.dolphin.desktop", "icon": "folder" },
    { "desktopId": "brave-browser.desktop", "icon": "/sciezka/do/wlasnej-ikony.svg" }
  ]
}
```

- **Pole `icon`:**
  - `null`: ikona z pliku `.desktop`.
  - Tekst bez `/`: nazwa ikony z motywu.
  - Ścieżka: własny plik.
- **Pierwsze uruchomienie:** domyślna konfiguracja powstaje z aplikacji, które **faktycznie są zainstalowane** (terminal, menedżer plików, przeglądarka itd.). Wartości w przykładzie wyżej są tylko ilustracją.

## 9. Języki

- **Pliki:** `shell/i18n/pl.json` i `shell/i18n/en.json`.
- **Teksty:** wszystkie napisy interfejsu przechodzą przez jedną funkcję tłumaczącą.
- **Brak klucza:** wyświetla się tekst angielski.

## 10. Wygląd (tokeny z projektu Halo)

| Token | Wartość |
|---|---|
| Tło / przyciemnienie | `#0E1013` (przyciemnienie z kryciem 85%) |
| Powierzchnia | `#161A1F` |
| Linia | `rgba(255,255,255,0.10)` |
| Tekst | `#E8EAED` |
| Tekst wyciszony | `#8A9099` |
| Ikony nieaktywne | `#B4BAC2` |
| Akcent (aureola) | `#F4D58D`; warianty na później: `#9ED0FF`, `#B8E0C0`, `#F2A7A0` |
| Fonty | Geist (interfejs), Geist Mono (liczby, kalkulator); zapasowo systemowe sans i mono |

**Wymiary (piksele logiczne, z poszanowaniem skali monitora w Hyprlandzie):**

- **Pierścień:** promień 240 px, obrys 1,5 px w kolorze akcentu z kryciem 35%.
- **Przyciski aplikacji:**
  - Rozmiar i tło: 56 px, okrągłe, tło w kolorze powierzchni, obrys w kolorze linii.
  - Ikony: 28 px.
  - Zaznaczony przycisk: obrys 1,5 px w kolorze akcentu.
- **Środek:**
  - Pole wyszukiwania: 260 × 48 px, w pełni zaokrąglone.
  - Pod polem: nazwa aplikacji (16 px, grubość 500) i podpowiedź „Enter — uruchom” (12 px, kolor wyciszony).
- **Spójność:** mako i hyprlock używają tych samych kolorów i fontu.

## 11. Etapy

Każdy etap to około 1–2 sesji pracy. Prompty poniżej można wkleić do Claude Code bez zmian.

### Etap 0: fundament i sesja

**Gotowe, gdy:**
- Publiczne repo na GitHubie zawiera README i ten plik.
- Na ekranie logowania jest sesja „Halo”.
- Po zalogowaniu działa Hyprland z tapetą, powiadomieniami (test: `notify-send test`) i blokadą (Super+L).
- Wylogowanie i powrót do Plasmy działają, a Plasma jest nietknięta.

> Przeczytaj HALO_SPEC.md. Robimy tylko Etap 0. Najpierw sprawdź, które pakiety z sekcji 3 są zainstalowane, i pokaż mi komendę instalacji brakujących. Niczego nie instaluj i nie używaj sudo bez mojej zgody. Nie zmieniaj ~/.config/hypr ani konfiguracji Plasmy. Sprawdź w aktualnej dokumentacji Hyprlanda, jak poprawnie uruchomić sesję z osobnym plikiem konfiguracyjnym i co jest potrzebne dla grafiki hybrydowej z NVIDIA. Na końcu wypisz krótką instrukcję testu krok po kroku i zrób commit.

### Etap 1: pierścień bez wyszukiwania

**Gotowe, gdy:**
- Alt+Spacja otwiera pierścień na monitorze z kursorem, a kursor przeskakuje na środek.
- Aplikacje są wczytywane z config.json, kliknięcie je uruchamia.
- Esc i kliknięcie obok zamykają launcher, animacja działa.
- Wszystko działa także z zewnętrznym monitorem.

> Przeczytaj HALO_SPEC.md. Robimy tylko Etap 1. Odwzoruj wygląd z sekcji 10. Sprawdź w dokumentacji zainstalowanych wersji Quickshell i Hyprlanda, jak zrobić globalny skrót, okno na wierzchu z fokusem klawiatury, wybór monitora z kursorem i przesunięcie kursora. Nie zgaduj API. Kod komentuj krótko po polsku, bo uczę się QML. Na końcu instrukcja testu i commit.

### Etap 2: wyszukiwanie aplikacji i klawiatura

**Gotowe, gdy:**
- Pisanie filtruje aplikacje na pierścieniu, z ignorowaniem polskich znaków.
- Strzałki, Tab i Enter działają.
- Bez wyników pojawia się komunikat.
- Wpis zaczynający się od `;` pokazuje „Komendy wkrótce”.

> Przeczytaj HALO_SPEC.md. Robimy tylko Etap 2. Zbuduj wyszukiwanie jako dostawców wyników (sekcja 6), żeby później łatwo dodać pliki, internet i komendy. Na końcu instrukcja testu i commit.

### Etap 3: kalkulator

**Gotowe, gdy:**
- `2+2*2` pokazuje `= 6`, a `10,5/2` pokazuje `= 5,25`.
- Enter kopiuje wynik do schowka.
- Błędne wyrażenie nie powoduje awarii.
- Parser ma testy uruchamiane jednym skryptem.

> Przeczytaj HALO_SPEC.md. Robimy tylko Etap 3. Napisz własny parser wyrażeń, bez eval i Function. Dodaj plik z przypadkami testowymi i skrypt, który je uruchamia. Na końcu instrukcja testu i commit.

### Etap 4: Ustawienia Halo

**Gotowe, gdy:**
- Okno pozwala dodawać, usuwać i przestawiać aplikacje (od 4 do 12).
- Ikonę można zmienić na ikonę z motywu albo na własny plik PNG/SVG.
- Zmiany zapisują się do config.json i od razu widać je w launcherze.

> Przeczytaj HALO_SPEC.md. Robimy tylko Etap 4. Okno ma używać kolorów i fontów z sekcji 10. Na końcu instrukcja testu i commit.

### Etap 5: języki i wydanie v0.1

**Gotowe, gdy:**
- Przełącznik PL/EN zmienia wszystkie teksty.
- README zawiera instalację, skróty, zrzuty ekranu i sposób awaryjnego powrotu do Plasmy.
- Repo ma tag `v0.1.0`.

> Przeczytaj HALO_SPEC.md. Robimy tylko Etap 5. Sprawdź, czy żaden tekst interfejsu nie omija tłumaczeń. Uzupełnij README. Na końcu instrukcja testu, commit i tag v0.1.0.

## 12. Później (nie robić w v1)

- **Wyszukiwanie:** w plikach i w internecie (DuckDuckGo).
- **Komendy po `;`:** np. `;plik`, `;claude` (pytanie do Claude), plus konfigurowalne prefiksy i skróty.
- **Elementy z projektu Halo:**
  - górny pasek: obszary robocze, zegar, wskaźniki;
  - dolny pasek: przycisk Halo, otwarte aplikacje;
  - panel szybkich ustawień.
- **Powiadomienia:** przeniesienie do Quickshell w stylu Halo.
- **Docelowo:** Halo jako jedyna sesja, zamiast Plasmy.

## 13. Zasady pracy dla Claude Code

- **Etapy:** jeden etap naraz. Kolejny zaczynasz dopiero na prośbę autora.
- **Pakiety i sudo:** bez zgody autora niczego nie instalujesz i nie używasz sudo. Zawsze pokazujesz komendę.
- **Nietykalne pliki:** `~/.config/hypr`, `~/.config/kde*` i pliki Plasmy.
- **API:** sprawdzaj w dokumentacji zainstalowanych wersji, bo Quickshell i Hyprland szybko się zmieniają. Nie zgaduj.
- **Zależności:** żadnych spoza sekcji 3 bez uzasadnienia.
- **Testy:** każdy etap kończy się instrukcją testu dla autora, krok po kroku.
- **Commity:** małe, z opisami po angielsku. Komentarze w kodzie po polsku.
