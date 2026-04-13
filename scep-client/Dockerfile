FROM alpine:latest
RUN apk --no-cache update
RUN apk --no-cache upgrade
RUN apk --no-cache add \
    bash ca-certificates certmonger curl dbus nodejs npm openssl
ENV CERTMONGER_CAS_DIR=/data/certmonger/cas
ENV CERTMONGER_REQUESTS_DIR=/data/certmonger/requests
ENV SCEP_DIR=/data/scep
COPY /app/package.* /app/
RUN cd /app && npm install --production
COPY /*.sh /
COPY /app/*.ts /app/
RUN chmod +x /*.sh /app/*.ts
VOLUME /data
ENTRYPOINT [ "/entrypoint.sh" ]
CMD ["/poll.sh" ]
