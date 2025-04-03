FROM rocker/tidyverse:4.4


RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       libcurl4-openssl-dev \
       libssl-dev \
       cmake \
       build-essential \
       python3-venv \
       python3-pip \
       libboost-all-dev \
       libpython3-dev \
       libharfbuzz-dev \
       libxml2-dev \
       libfontconfig1-dev \
       libfribidi-dev \
       libtiff-dev \
       libhts-dev \
       libfftw3-dev \
       librsvg2-dev \
       samtools \
       bcftools \
       pandoc \
       libfreetype-dev \
       liblzma-dev \
       zip unzip \
       dos2unix \
       libicu-dev \
       libglpk-dev \
       libgmp3-dev \
       zlib1g-dev \
       libbz2-dev \
       libhdf5-dev \
       libxt-dev libx11-dev \
       libcairo2-dev \
       libpng-dev \
    && rm -rf /var/lib/apt/lists/* \
    && R -q -e 'install.packages(c("curl", "BiocManager", "RhpcBLASctl"))'
