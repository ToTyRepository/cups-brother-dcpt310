FROM anujdatar/cups:latest

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Warsaw \
    LANG=C

# Włącz architekturę i386 i doinstaluj biblioteki 32-bit
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y \
      curl \
      libc6:i386 \
      libstdc++6:i386 \
      libgcc-s1:i386  || apt-get install -y libgcc1:i386 \
 && rm -rf /var/lib/apt/lists/*

# Pobierz sterownik Brothera DCP-T310 (.deb) – URL z oficjalnej strony Brothera
RUN curl -L -o /tmp/dcpt310pdrv.deb "https://download.brother.com/welcome/dlf103618/dcpt310pdrv-1.0.1-0.i386.deb" \
 && dpkg -i --force-all /tmp/dcpt310pdrv.deb || true \
 && dpkg --configure -a \
 && rm -f /tmp/dcpt310pdrv.deb

# Na tym etapie w obrazie masz:
# - zainstalowane liby 32-bit
# - /usr/share/cups/model/Brother/brother_dcpt310_printer_en.ppd
# - /usr/lib/cups/filter/brother_lpdwrapper_dcpt310 (symlink do /opt/brother/Printers/dcpt310/...)
# - /opt/brother/Printers/dcpt310/... (filtry, configi)
