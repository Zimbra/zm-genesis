Steps to run genesis using the latest code:__

1. Clone following git repos:_
   git clone https://github.com/Zimbra/zimbra-package-stub.git_
   git clone https://github.com/Zimbra/zm-zcs.git_
   git clone https://github.com/Zimbra/zm-mailbox.git_
   git clone ssh://git@stash.corp.synacor.com:7999/zimbra/zm-genesis.git__

2. Enter into zm-mailbox directory and execute following command to generate necessary zimbra dependencies_
   ant clean-ant publish-local-all -Dzimbra.buildinfo.version=8.8.3_GA__

3. Enter into zm-genesis directory and run ant build-genesis__

4. After step 4 is successful, genesis.tar should created under $HOME/zm-genesis/build/__

5. Inorder to deploy genesis.tar and run it on testmachine follow instructions mentioned at http://wiki.eng.zimbra.com/index.php/ZimbraQA/HarnessGenesis#Structure

