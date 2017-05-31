FROM centos:7.3.1611

ENV RUBY_VERSION 2.3.1
ENV RUBY_GEM 2.3.0
ENV PASSENGER_VERSION 5.1.2

RUN yum -y localinstall https://dev.mysql.com/get/mysql57-community-release-el7-9.noarch.rpm

RUN curl --silent --location https://rpm.nodesource.com/setup_7.x | bash -

# Install dependence packages
RUN yum update -y && yum install -y expat-devel gettext-devel httpd mod_ssl \
  git gcc gcc-c++ make automake tar \
  autoconf wget openssh-clients openssl-devel \
  zlib-devel httpd-devel libcurl-devel libxml2-devel \
  libxslt-devel patch readline-devel libffi-devel \
  libtool bison libyaml-devel sqlite-devel sysstat \
  ruby-devel libpng-devel libjpeg-devel \
  bzip2-devel giflib-devel libtiff-devel \
  freetype-devel nkf vim-enhanced \
  bzip2 htop nodejs mysql-community-devel

RUN yum install -y postfix mailx cyrus-sasl cyrus-sasl-plain cyrus-sasl-md5 rsyslog && systemctl enable postfix

RUN ln -sf /usr/share/zoneinfo/Asia/Ho_Chi_Minh /etc/localtime

### Create user vyvu and install rbenv
RUN groupadd -g 507 vyvu && useradd -u 507 -g 507 -m vyvu

RUN groupadd rbenv && usermod -a -G rbenv vyvu

RUN echo 'export RBENV_ROOT=/usr/local/rbenv' > /etc/profile.d/rbenv.sh && \
    echo 'export PATH="$RBENV_ROOT/bin:$PATH"' >> /etc/profile.d/rbenv.sh && \
    echo 'eval "$(rbenv init -)"' >> /etc/profile.d/rbenv.sh

RUN mkdir -p /usr/local/rbenv && \
    git clone git://github.com/sstephenson/rbenv.git /usr/local/rbenv && \
    git clone git://github.com/sstephenson/ruby-build.git /usr/local/rbenv/plugins/ruby-build && \
    git clone git://github.com/jamis/rbenv-gemset.git /usr/local/rbenv/plugins/rbenv-gemset

RUN source /etc/profile.d/rbenv.sh && \
    rbenv install $RUBY_VERSION && \
    rbenv global $RUBY_VERSION && \
    gem install bundle && \
    rbenv rehash && \
    ln -s /usr/local/rbenv/versions/$RUBY_VERSION /usr/local/rbenv/versions/current && \
    chown root.rbenv /usr/local/rbenv -R && \
    find /usr/local/rbenv/ -type d -exec chmod 775 {} +

RUN source /etc/profile.d/rbenv.sh && \
    gem install passenger -v $PASSENGER_VERSION && \
    passenger-install-nginx-module --auto --language ruby \
    --prefix=/etc/nginx --extra-configure-flags=" \
    --conf-path=/etc/nginx/nginx.conf \
    --sbin-path=/usr/sbin/nginx --user=nobody --group=nginx \
    --http-log-path=/var/log/nginx/access.log \
    --error-log-path=/var/log/nginx/error.log \
    --lock-path=/var/run/nginx.lock --pid-path=/var/run/nginx.pid  \
    --with-file-aio --with-http_mp4_module --with-ipv6 \
    --with-http_auth_request_module --with-http_dav_module \
    --with-http_flv_module --with-http_gunzip_module \
    --with-http_random_index_module --with-http_sub_module  \
    --with-http_secure_link_module --with-http_slice_module \
    --with-mail --with-mail_ssl_module --with-stream \
    --with-stream_ssl_module --with-threads"

# Install nginx and passenger
RUN yum install -y ntp
RUN chkconfig ntpd on && ntpdate pool.ntp.org

#RUN service ntpd start
RUN mkdir -p /etc/nginx/conf.d && \
  echo "passenger_root /usr/local/rbenv/versions/$RUBY_VERSION/lib/ruby/gems/$RUBY_GEM/gems/passenger-$PASSENGER_VERSION;" >> /etc/nginx/conf.d/passenger.conf && \
  echo "passenger_ruby /usr/local/rbenv/versions/$RUBY_VERSION/bin/ruby;" >> /etc/nginx/conf.d/passenger.conf

# Create root app and bundle install
RUN mkdir -p /home/projects/myapp/current/public
ADD ./Gemfile /home/projects/myapp/current/Gemfile
ADD ./Gemfile.lock /home/projects/myapp/current/Gemfile.lock
WORKDIR /home/projects/myapp/current

RUN source /etc/profile.d/rbenv.sh && \
    gem install rainbow -v '2.2.1' && \
    bundle install && \
    rm -rf /home/projects/myapp/current

RUN yum clean all
RUN yum install rsyslog -y
RUN systemctl enable rsyslog
EXPOSE 80 25

CMD ["nginx", "-g", "daemon off;"]
