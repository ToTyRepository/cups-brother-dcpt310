FROM anujdatar/cups:latest

ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Europe/Warsaw \
    LANG=C

# Architektura i386 + potrzebne pakiety
RUN dpkg --add-architecture i386 \
 && apt-get update \
 && apt-get install -y \
      curl \
      ghostscript \
      cups-filters \
      cups-ipp-utils \ 
      libc6:i386 \
      libstdc++6:i386 \
      libgcc-s1:i386 || apt-get install -y libgcc1:i386 \
 && rm -rf /var/lib/apt/lists/*

# Sterownik Brother DCP‑T310 (i386)
RUN curl -L -o /tmp/dcpt310pdrv.deb "https://download.brother.com/welcome/dlf103618/dcpt310pdrv-1.0.1-0.i386.deb" \
 && dpkg -i --force-all /tmp/dcpt310pdrv.deb || true \
 && dpkg --configure -a \
 && rm -f /tmp/dcpt310pdrv.deb
