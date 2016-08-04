FROM centos:centos6

RUN yum install -y http://download.fedoraproject.org/pub/epel/6/i386/epel-release-6-8.noarch.rpm
RUN yum install -y --enablerepo=centosplus 389-ds
RUN yum clean all

ADD ds-setup.inf /ds-setup.inf
ADD users.ldif /users.ldif

# The 389-ds setup will fail because the hostname can't reliable be determined, so we'll bypass it and then install.
RUN sed -i 's/checkHostname {/checkHostname {\nreturn();/g' /usr/lib64/dirsrv/perl/DSUtil.pm
RUN setup-ds-admin.pl --silent --file /ds-setup.inf
#RUN ldapadd -x -D "cn=Directory Manager" -f users.ldif -w password
#RUN rm /*.ldif

EXPOSE 389

CMD /usr/sbin/ns-slapd -D /etc/dirsrv/slapd-dir && tail -F /var/log/dirsrv/slapd-dir/access
