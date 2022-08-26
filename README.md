## 🐳 azure-sql-edge Docker containers

Build script that generates azure-sql-edge:latest containers with open-source [go-sqlcmd](https://github.com/microsoft/go-sqlcmd) and [docker-healthcheck](https://github.com/rpinz/azure-sql-edge).  This is particularly useful when using ARM64 architecture for Azure SQL Edge.

 - [rpinz/azure-sql-edge:latest](https://hub.docker.com/r/rpinz/azure-sql-edge)
 - [version list JSON](https://mcr.microsoft.com/v2/azure-sql-edge/tags/list)

## 📦 Installation

Clone the [repository](https://github.com/rpinz/azure-sql-edge.git) in `${HOME}/containers`:

```shellscript
$ cd ${HOME}/containers
$ git clone https://github.com/rpinz/azure-sql-edge.git
```

### ⚒  Build:

Build containers locally
```shellscript
$ cd ${HOME}/containers/azure-sql-edge
$ ./build.sh local no-cache
```

Build containers and push to registry
```shellscript
$ cd ${HOME}/containers/azure-sql-edge
$ ./build.sh build no-cache
```

Build multi-arch containers and push to registry
```shellscript
$ cd ${HOME}/containers/azure-sql-edge
$ ./build.sh buildx no-cache
```

TODO:
 - [ ] Quality control testing
