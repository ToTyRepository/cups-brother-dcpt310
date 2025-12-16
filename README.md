CUPS + Brother DCP‑T310 (Docker / TrueNAS SCALE)
Ten projekt zawiera Dockerfile oraz konfigurację CI do zbudowania obrazu CUPS z wbudowanym sterownikiem drukarki Brother DCP‑T310.
Obraz jest przygotowany z myślą o:

domowym / małym serwerze wydruku,
TrueNAS SCALE (Docker Compose App),
drukarce USB Brother DCP‑T310.
Uwaga: projekt obsługuje drukowanie. Skanowanie nie jest realizowane przez CUPS (do skanera potrzebne jest SANE/brscan – osobny temat).

Co jest w obrazie
Obraz ghcr.io/totyrepository/cups-brother-dcpt310:latest (budowany z Dockerfile):

bazuje na:

anujdatar/cups:latest (CUPS + Debian),
dodaje architekturę i386 i biblioteki 32‑bit:

libc6:i386
libstdc++6:i386
libgcc-s1:i386 (z fallbackiem na libgcc1:i386)
curl (do pobrania .deb),
pobiera i instaluje sterownik Brother DCP‑T310:

.deb z oficjalnej strony Brothera:
https://download.brother.com/welcome/dlf103618/dcpt310pdrv-1.0.1-0.i386.deb
Po zbudowaniu obrazu w środku znajdują się m.in.:

/usr/share/cups/model/Brother/brother_dcpt310_printer_en.ppd
/usr/lib/cups/filter/brother_lpdwrapper_dcpt310
(symlink do /opt/brother/Printers/dcpt310/cupswrapper/brother_lpdwrapper_dcpt310)
/opt/brother/Printers/dcpt310/... – filtry, konfiguracja sterownika Brothera
Dzięki temu kontener:

od razu „zna” sterownik Brothera,
może drukować na DCP‑T310 po USB, bez ręcznej instalacji .deb w kontenerze.
Wymagania
Host z Dockerem lub TrueNAS SCALE (włączone Apps / Docker Compose).
Drukarka Brother DCP‑T310 podłączona przez USB do hosta (TrueNAS / Linux).
Przekazanie USB do kontenera:
devices: - /dev/bus/usb:/dev/bus/usb
privileged: true
Na TrueNAS – dataset na konfigurację CUPS, np.:
/mnt/POOL_01/cups/etc
/mnt/POOL_01/cups/log
/mnt/POOL_01/cups/spool
Dockerfile
Plik Dockerfile:

FROM anujdatar/cups:latest

ENV DEBIAN_FRONTEND=noninteractive
TZ=Europe/Warsaw
LANG=C

Włącz architekturę i386 i doinstaluj biblioteki 32-bit
RUN dpkg --add-architecture i386
&& apt-get update
&& apt-get install -y
curl
libc6:i386
libstdc++6:i386
libgcc-s1:i386 || apt-get install -y libgcc1:i386
&& rm -rf /var/lib/apt/lists/*

Pobierz sterownik Brothera DCP-T310 (.deb) – URL z oficjalnej strony Brothera
RUN curl -L -o /tmp/dcpt310pdrv.deb "https://download.brother.com/welcome/dlf103618/dcpt310pdrv-1.0.1-0.i386.deb"
&& dpkg -i --force-all /tmp/dcpt310pdrv.deb || true
&& dpkg --configure -a
&& rm -f /tmp/dcpt310pdrv.deb

Na tym etapie w obrazie masz:
- zainstalowane liby 32-bit
- /usr/share/cups/model/Brother/brother_dcpt310_printer_en.ppd
- /usr/lib/cups/filter/brother_lpdwrapper_dcpt310 (symlink do /opt/brother/Printers/dcpt310/...)
- /opt/brother/Printers/dcpt310/... (filtry, configi)
CI: GitHub Actions – build + push do GHCR
Plik .github/workflows/build.yml:

name: Build and publish CUPS Brother image

on:
push:
branches: [ main ]
workflow_dispatch:

jobs:
build:
runs-on: ubuntu-latest
permissions:
contents: read
packages: write

text

steps:
  - name: Checkout repository
    uses: actions/checkout@v4

  - name: Set up Docker Buildx
    uses: docker/setup-buildx-action@v3

  - name: Log in to GitHub Container Registry
    uses: docker/login-action@v3
    with:
      registry: ghcr.io
      username: ${{ github.actor }}
      password: ${{ secrets.GITHUB_TOKEN }}

  - name: Build and push image
    uses: docker/build-push-action@v6
    with:
      context: .
      push: true
      tags: ghcr.io/totyrepository/cups-brother-dcpt310:latest
Po każdym pushu na main (lub ręcznie z zakładki Actions) workflow:

zbuduje obraz z Dockerfile,
opublikuje go do GHCR jako:
ghcr.io/totyrepository/cups-brother-dcpt310:latest.
Uwaga: jeśli obraz ma być dostępny z TrueNAS bez logowania:

ustaw pakiet w GHCR jako Public
(Profile → Packages → cups-brother-dcpt310 → Package settings → Visibility: Public),
lub skonfiguruj w TrueNAS rejestr GHCR z tokenem (read:packages).
Użycie: TrueNAS SCALE (Docker Compose App)
1. Przygotuj dataset i katalogi
W GUI TrueNAS:

Storage → Datasets → utwórz dataset, np.:
POOL_01/cups
W shellu TrueNAS:

mkdir -p /mnt/POOL_01/cups/etc
mkdir -p /mnt/POOL_01/cups/log
mkdir -p /mnt/POOL_01/cups/spool

2. Konfiguracja Docker Compose w GUI
W Apps → Add → Docker Compose App (lub podobnie):

Wklej:

services:
cups:
container_name: cups
image: ghcr.io/totyrepository/cups-brother-dcpt310:latest
restart: unless-stopped

text

privileged: true
devices:
  - /dev/bus/usb:/dev/bus/usb

environment:
  - TZ=Europe/Warsaw
  - CUPSADMIN=admin
  - CUPSPASSWORD=AdminPassword123

ports:
  - "631:631"

volumes:
  - /mnt/POOL_01/cups/etc:/etc/cups
  - /mnt/POOL_01/cups/log:/var/log/cups
  - /mnt/POOL_01/cups/spool:/var/spool/cups
Ostrzeżenie w logu typu „the attribute version is obsolete” oznacza tylko, że TrueNAS ignoruje version: z compose – nie jest potrzebne.

Zapisz / Deploy. Po chwili appka cups powinna mieć status Running.

Konfiguracja CUPS (dodanie Brother DCP‑T310)
W przeglądarce:

http://IP_TWOJEGO_TREUNAS:631

Zaloguj się:

użytkownik: admin
hasło: AdminPassword123 (lub inne, jeśli zmieniłeś CUPSPASSWORD).
Administration → Add Printer:

wybierz urządzenie USB:
Brother DCP-T310 / usb://Brother/DCP-T310?serial=...
w kroku sterownika:
wybierz „Brother” → model DCP‑T310
(po zainstalowaniu pakietu .deb sterownik jest dostępny na liście).
Po zapisaniu:

drukarka pojawi się w zakładce Printers jako Brother_DCP-T310 (lub podobnie),
kliknij na nią → Print Test Page,
jeśli wszystko jest OK, drukarka fizycznie wydrukuje stronę testową.
Trwałość konfiguracji
Dzięki volume’om:

/etc/cups → /mnt/POOL_01/cups/etc,
/var/log/cups → /mnt/POOL_01/cups/log,
/var/spool/cups → /mnt/POOL_01/cups/spool,
przechowujesz całą konfigurację CUPS na dysku hosta:

printers.conf – kolejki,
/etc/cups/ppd/*.ppd – sterowniki przypisane do drukarek,
cupsd.conf – ustawienia serwera CUPS.
To oznacza:

restart kontenera / NAS‑a – konfiguracja zostaje,
skasowanie appki i utworzenie jej od nowa z tym samym compose – CUPS od razu widzi stare kolejki i PPD.
Logi i diagnostyka
Logi kontenera (Docker / TrueNAS)
Na hoście:

docker logs -f cups

Logi CUPS na datasiecie
Na hoście TrueNAS:

tail -f /mnt/POOL_01/cups/log/error_log
tail -f /mnt/POOL_01/cups/log/access_log

Logi wrappera Brothera (jeśli włączysz DEBUG w brother_lpdwrapper_dcpt310)
W kontenerze:

docker exec -it cups bash

tail -f /tmp/br_cupswrapper_ink.log
tail -f /tmp/br_cupswrapper_ink_lpderr

Uwagi licencyjne
Sterownik Brothera DCP‑T310 (dcpt310pdrv-1.0.1-0.i386.deb) jest własnością Brother Industries, Ltd.
W Dockerfile jest on pobierany bezpośrednio z serwera Brothera podczas builda obrazu.
To repo nie hostuje pliku .deb – zawiera tylko instrukcję (URL) do jego pobrania.
Publiczne udostępnianie obrazu Dockera, który zawiera już zainstalowany sterownik:

oznacza praktycznie redystrybucję binariów Brothera,
do użytku prywatnego i testowego jest to zwykle akceptowane, ale:
jeśli planujesz szeroką publiczną dystrybucję obrazu,
zapoznaj się dokładnie z licencją/EULA sterownika Brothera.
