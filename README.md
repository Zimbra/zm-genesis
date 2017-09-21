__Steps to build genesis.tar using the latest code:__

1. Clone following git repos:
   * git clone https://github.com/Zimbra/zimbra-package-stub.git
   * git clone https://github.com/Zimbra/zm-zcs.git
   * git clone https://github.com/Zimbra/zm-mailbox.git
   * git clone https://github.com/Zimbra/zm-genesis.git

2. Enter into zm-mailbox directory and execute following command to generate necessary zimbra dependencies
   ```ant clean-ant publish-local-all -Dzimbra.buildinfo.version=8.8.3_GA```
   (you may need to create /root/.ivy2/cache directory manually before running above command)

3. Enter into zm-genesis directory and run ```ant build-genesis```

4. After step 4 is successful, genesis.tar should created under ```$HOME/zm-genesis/build/```

5. Once you have genesis.tar, copy it under /opt/qa/ and extract it.

__Pre-requisites to run genesis tests__

Once you have genesis.tar file under /opt/qa directory, you will 

1. Setup the ruby environment using following steps:
   * sudo gpg --keyserver keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3"
   * curl -sSL https://get.rvm.io | bash -s stable
   * source /etc/profile.d/rvm.sh
   * rvm install 2.0.0 --with-zlib-directory=/usr/local/rvm/usr --with-openssl-directory=/usr/local/rvm/usr
   * gem install soap4r-spox log4r net-ldap json httpclient
   * rvm --default use 2.0.0

2. Install basic linux packages man, psutil, tzdata, psmisc, ruby-dev, gcc. 
3. SNMP package since they scan admin mailbox for certain notification mails. 
4. Tests expect default timezone to be PDT. There are lot of IMAP tests which has the expected results mentioned in PDT format. So configure default time zone using "dpkg-reconfigure tzdata"
5. Disable setting in /root/.profile which prevents users on the machine writing to your current terminal device by commenting line msg n.
6. ZCS installation needs to have a default domain which is same has hostname. This is because lot of tests are using zmhostname command to configure domains for test accounts. This will be fixed soon to 
7. Admin password needs to be 'test123'.
8. Create symlink as ln -s /usr/bin/env /bin/env 

