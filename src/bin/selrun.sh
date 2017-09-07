#!/bin/bash
SERVER=$1
SERVER=${SERVER:=qa62.lab.zimbra.com}
BRANCH=$3
BRANCH=${BRANCH:=main}
OS=$2
OS=${OS:=RHEL4}
/opt/qa/tools/kickoffTest.rb browserperf2 $BRANCH $OS "Selng&cmachine=browserperf2&s_locale=en_GB&s_browser=safari&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb browserperf2 $BRANCH $OS "Selng&cmachine=browserperf2&s_locale=da&s_browser=firefox&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb browserperf2 $BRANCH $OS "Selng&cmachine=browserperf2&s_locale=zh_CN&s_browser=safari&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qafe2 $BRANCH $OS "Selng&cmachine=qafe2&s_locale=en_US&s_browser=firefox&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qafe2 $BRANCH $OS "Selng&cmachine=qafe2&s_locale=nl&s_browser=firefox&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qafe2 $BRANCH $OS "Selng&cmachine=qafe2&s_locale=pl&s_browser=firefox&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qa33-vista-qtp2 $BRANCH $OS "Selng&cmachine=qa33-vista-qtp2&s_locale=pt_BR&s_browser=iexplore&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qa33-vista-qtp2 $BRANCH $OS "Selng&cmachine=qa33-vista-qtp2&s_locale=ru&s_browser=firefox&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qa33-vista-qtp2 $BRANCH $OS "Selng&cmachine=qa33-vista-qtp2&s_locale=zh_CN&s_browser=iexplore&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qa33-vista-qtp1 $BRANCH $OS "Selng&cmachine=qa33-vista-qtp1&s_locale=ru&s_browser=iexplore&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qa33-vista-qtp1 $BRANCH $OS "Selng&cmachine=qa33-vista-qtp1&s_locale=de&s_browser=firefox&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qa33-vista-qtp1 $BRANCH $OS "Selng&cmachine=qa33-vista-qtp1&s_locale=sv&s_browser=firefox&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qafe1 $BRANCH $OS "Selng&cmachine=qafe1&s_locale=ar&s_browser=firefox&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qafe1 $BRANCH $OS "Selng&cmachine=qafe1&s_locale=es&s_browser=safari&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb qafe1 $BRANCH $OS "Selng&cmachine=qafe1&s_locale=ko&s_browser=iexplore&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb browserperf1 $BRANCH $OS "Selng&cmachine=browserperf1&s_locale=en_US&s_browser=firefox&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb browserperf1 $BRANCH $OS "Selng&cmachine=browserperf1&s_locale=hi&s_browser=safari&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
/opt/qa/tools/kickoffTest.rb browserperf1 $BRANCH $OS "Selng&cmachine=browserperf2&s_locale=en_US&s_browser=firefox&s_server=$SERVER" N $4 >> /opt/qa/tools/${SERVER}.txt 2>&1
