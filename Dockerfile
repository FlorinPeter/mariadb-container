FROM rhscl/s2i-core-rhel7

# MariaDB image for OpenShift.
#
# Volumes:
#  * /var/lib/mysql/data - Datastore for MariaDB
# Environment:
#  * $MYSQL_USER - Database user name
#  * $MYSQL_PASSWORD - User's password
#  * $MYSQL_DATABASE - Name of the database to create
#  * $MYSQL_ROOT_PASSWORD (Optional) - Password for the 'root' MySQL account

ENV MYSQL_VERSION=10.2 \
    APP_DATA=/opt/app-root/src \
    HOME=/var/lib/mysql \
    SUMMARY="MariaDB 10.2 SQL database server" \
    DESCRIPTION="MariaDB is a multi-user, multi-threaded SQL database server. The container \
image provides a containerized packaging of the MariaDB mysqld daemon and client application. \
The mysqld server daemon accepts connections from clients and provides access to content from \
MariaDB databases on behalf of the clients."

LABEL summary="$SUMMARY" \
      description="$DESCRIPTION" \
      io.k8s.description="$DESCRIPTION" \
      io.k8s.display-name="MariaDB 10.2" \
      io.openshift.expose-services="3306:mysql" \
      io.openshift.tags="database,mysql,mariadb,mariadb102,rh-mariadb102" \
      com.redhat.component="rh-mariadb102-container" \
      name="rhscl/mariadb-102-rhel7" \
      version="1" \
      usage="docker run -d -e MYSQL_USER=user -e MYSQL_PASSWORD=pass -e MYSQL_DATABASE=db -p 3306:3306 rhscl/mariadb-102-rhel7" \
      maintainer="SoftwareCollections.org <sclorg@redhat.com>"

EXPOSE 3306

# This image must forever use UID 27 for mysql user so our volumes are
# safe in the future. This should *never* change, the last test is there
# to make sure of that.
COPY MariaDB.repo /etc/yum.repos.d/MariaDB.repo

RUN yum install -y yum-utils && \
    prepare-yum-repositories rhel-server-rhscl-7-rpms && \
    INSTALL_PKGS="rsync tar gettext hostname bind-utils groff-base shadow-utils MariaDB-server MariaDB-client" && \
    yum install -y --setopt=tsflags=nodocs $INSTALL_PKGS && \
    rpm -V $INSTALL_PKGS && \
    yum clean all && \
    mkdir -p /var/lib/mysql/data && chown -R mysql.0 /var/lib/mysql && \
    test "$(id mysql)" = "uid=999(mysql) gid=998(mysql) groups=998(mysql)"

# Get prefix path and path to scripts rather than hard-code them in scripts
ENV CONTAINER_SCRIPTS_PATH=/usr/share/container-scripts/mysql \
    MYSQL_PREFIX=/usr   

COPY root-common /
COPY s2i-common/bin/ $STI_SCRIPTS_PATH
COPY root /

# this is needed due to issues with squash
# when this directory gets rm'd by the container-setup
# script.
# Also reset permissions of filesystem to default values
RUN rm -rf /etc/my.cnf.d/* && \
    /usr/libexec/container-setup && \
    rpm-file-permissions

VOLUME ["/var/lib/mysql/data"]

USER 999

ENTRYPOINT ["container-entrypoint"]
CMD ["run-mysqld"]
