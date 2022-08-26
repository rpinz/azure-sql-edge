# syntax=docker/dockerfile:1

ARG EDGEVERSION=1.0.6

# build go-sqlcmd
FROM docker.io/rpinz/golang:1.19-bionic AS build
ARG EDGEVERSION
RUN go install github.com/microsoft/go-sqlcmd/cmd/sqlcmd@latest

# add sqlcmd to azure-sql-edge
FROM mcr.microsoft.com/azure-sql-edge:${EDGEVERSION}
USER root
RUN mkdir -p /opt/sqlcmd/bin
COPY --from=build /go/bin/sqlcmd /opt/sqlcmd/bin/sqlcmd
COPY ./docker-healthcheck /opt/sqlcmd/bin/docker-healthcheck
COPY ./mssql.conf /var/opt/mssql/mssql.conf
RUN chmod +x /opt/sqlcmd/bin/sqlcmd /opt/sqlcmd/bin/docker-healthcheck
EXPOSE 1433
USER mssql
HEALTHCHECK --interval=10s --timeout=10s --start-period=10s --retries=10 \
  CMD /opt/sqlcmd/bin/docker-healthcheck
ENTRYPOINT [ "/opt/mssql/bin/sqlservr" ]
CMD [ "--version" ]
