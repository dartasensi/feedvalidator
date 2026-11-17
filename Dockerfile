FROM debian:13-slim

# Set environment variables
# Notes:
# - DEBIAN_FRONTEND=noninteractive prevents interactive prompts during package installation
# - PYTHONUNBUFFERED=1 ensure Python doesn't buffer output
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HTTP_HOST=https://feedvalidator.org/ \
    SCRIPT_NAME=check.cgi \
    SCRIPT_FILENAME=/feedvalidator/check.cgi

# Install dependencies in a single layer without recommended extras
# Notes: 
# - apt-get already configured with /etc/apt/apt.conf.d/docker-clean
# - rdflib-jsonld is already integrated into rdflib > v0.6.1
# - python3-legacy-cgi is installed to provide the cgi module for Python >3.13
RUN apt-get update \
    && apt-get install --yes --no-install-recommends \
      apache2 \
      ca-certificates \
      python3 \
      python3-pip \
      python3-libxml2 \
      python3-rdflib \
      python3-legacy-cgi \
    && rm -rf /var/lib/apt/lists/*

# Configure Apache modules, ServerName, and Docker log forwarding
RUN a2dissite 000-default \
    && a2enmod cgid rewrite \
    && echo 'ServerName feedvalidator.org' >> /etc/apache2/apache2.conf \
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log

WORKDIR /feedvalidator

# Copy and enable the Apache virtual host configuration
COPY sites-available-feedvalidator.conf /etc/apache2/sites-available/feedvalidator.conf
RUN a2ensite feedvalidator

# Copy application code
COPY ./site /feedvalidator

EXPOSE 80

# Keep the container alive and forward signals directly to Apache
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]