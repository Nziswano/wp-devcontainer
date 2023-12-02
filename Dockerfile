ARG VARIANT=8
ARG USERNAME=vscode

FROM mcr.microsoft.com/vscode/devcontainers/php:${VARIANT}

ENV RAILS_DEVELOPMENT_HOSTS=".githubpreview.dev"

# Install Ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | \
  sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && \
  echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | \
  sudo tee /etc/apt/sources.list.d/ngrok.list && \
  sudo apt update && sudo apt install ngrok

# Install 1Password CLI
RUN ARCH="arm64" && \
wget "https://cache.agilebits.com/dist/1P/op2/pkg/v2.22.0/op_linux_${ARCH}_v2.22.0.zip" -O op.zip && \
unzip -d op op.zip && \
sudo mv op/op /usr/local/bin && \
rm -r op.zip op && \
sudo groupadd -f onepassword-cli && \
sudo chgrp onepassword-cli /usr/local/bin/op && \
sudo chmod g+s /usr/local/bin/op

# Install MariaDB client
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get install -y mariadb-client \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install php-mysql driver
RUN docker-php-ext-install mysqli pdo pdo_mysql

RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
  && chmod +x wp-cli.phar \
  && mv wp-cli.phar /usr/local/bin/wp && wp --info

# Install composer
RUN curl -sSL https://getcomposer.org/installer | php \
  && chmod +x composer.phar \
  && mv composer.phar /usr/local/bin/composer

# Install PHIVE
RUN wget -O phive.phar "https://phar.io/releases/phive.phar" \
	&& wget -O phive.phar.asc "https://phar.io/releases/phive.phar.asc" \
	&& gpg --keyserver hkps://keys.openpgp.org --recv-keys 0x6AF725270AB81E04D79442549D8A98B29B2D5D79 \
	&& gpg --verify phive.phar.asc phive.phar \
	&& rm phive.phar.asc \
	&& chmod +x phive.phar \
	&& sudo mv phive.phar /usr/local/bin/phive && phive version

# [Choice] Node.js version: none, lts/*, 16, 14, 12, 10
ARG NODE_VERSION="lts/*"
ARG NODE_MODULES="typescript aws-cdk prettier newman"
RUN if [ "${NODE_VERSION}" != "none" ]; then su vscode -c "umask 0002 && . /usr/local/share/nvm/nvm.sh && nvm install ${NODE_VERSION} 2>&1"; fi
RUN su vscode -c "source /usr/local/share/nvm/nvm.sh && npm install -g ${NODE_MODULES}" 2>&1

# Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip" \
&& unzip awscliv2.zip \
&& sudo ./aws/install

# Store vscode extensions between builds
ARG USERNAME=vscode
RUN mkdir -p /home/$USERNAME/.vscode-server/extensions \
    && chown -R $USERNAME \
        /home/$USERNAME/.vscode-server
