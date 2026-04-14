FROM codercom/code-server
USER root
RUN apt update -y
RUN apt upgrade -y
WORKDIR /root
RUN curl -fsSL https://get.docker.com -o get-docker.sh
RUN sh get-docker.sh
RUN adduser coder root
RUN apt install -y makepasswd
USER coder
RUN code-server --install-extension ms-azuretools.vscode-docker
USER root
COPY /entrypoint.sh /
RUN chmod +x /entrypoint.sh
USER coder
WORKDIR /home/coder/.local/share/code-server/User
COPY /settings.json ./
WORKDIR /config
COPY --chown=coder:coder /config ./
ENTRYPOINT ["/entrypoint.sh"]
CMD []
