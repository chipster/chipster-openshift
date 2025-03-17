FROM comp-r-4-4-3

# download and extract mothur
RUN apt update -y \ 
    && apt install -y unzip \
    && apt-get clean \
    && cd /opt/chipster/tools \
    && wget -nv https://github.com/mothur/mothur/releases/download/v1.48.2/Mothur.Ubuntu_22.zip \
    && unzip Mothur.Ubuntu_22.zip \
    && rm Mothur.Ubuntu_22.zip \
    && ls -lah

CMD ["sleep", "inf"]
