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


