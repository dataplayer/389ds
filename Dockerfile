FROM centos:centos7

RUN yum install -y epel-release \
    && yum update -y \
    && yum install -y 389-ds-base 389-adminutil \
    && yum clean all

#RUN yum install -y http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
#RUN yum install -y --enablerepo=centosplus 389-ds
#RUN yum clean all

ADD ds-setup.inf /ds-setup.inf
ADD users.ldif /users.ldif

# The 389-ds setup will fail because the hostname can't reliable be determined, so we'll bypass it and then install.
RUN useradd ldapadmin
RUN rm -fr /var/lock /usr/lib/systemd/system
RUN sed -i 's/checkHostname {/checkHostname {\nreturn();/g' /usr/lib64/dirsrv/perl/DSUtil.pm
RUN sed -i 's/updateSelinuxPolicy($inf);//g' /usr/lib64/dirsrv/perl/*
RUN sed -i '/if (@errs = startServer($inf))/,/}/d' /usr/lib64/dirsrv/perl/*
RUN setup-ds-admin.pl --silent --file /ds-setup.inf
RUN /usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir
RUN sleep 3
RUN ldapadd -H ldap:/// -f /users.ldif -x -D "cn=Directory Manager" -w password

EXPOSE 389

CMD /usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir && tail -F /var/log/dirsrv/slapd-dir/access
