if($0 == __FILE__)
  mydata = File.expand_path(__FILE__).reverse.sub(/.*?atad/,"").reverse;$:.unshift(mydata); $:.unshift(File.join(mydata, 'src', 'ruby')) #append library path
end 
 
require "model"
require "action/zmprov"
require "action/proxy"
require "action/sendmail"
require "action/verify"
require "net/imap"; require "action/imap" #Patch Net::IMAP library
require "set"

#
# Global variable declaration
#
current = Model::TestCase.instance()
current.description = "IMAP Append Negative test"

name = 'imap'+File.basename(__FILE__,'.rb')+Time.now.to_i.to_s
name = "admin" if ($0 == __FILE__)
testAccount = Model::TARGETHOST.cUser(name, Model::DEFAULTPASSWORD)

mimap = Net::IMAP.new(Model::TARGETHOST, Model::IMAPSSL, true)

include Action

 
#
# Setup
#
current.setup = [
   CreateAccount.new(testAccount.name,testAccount.password) 
]
message = <<EOF.gsub(/\n/, "\r\n")
Received: from localhost (localhost.localdomain [127.0.0.1])
	by dogfood.test.com (Postfix) with ESMTP id 40D0F36F824
	for <bhwang@dogfood.test.com>; Tue,  2 Aug 2005 08:03:15 -0700 (PDT)
Received: from dogfood.test.com ([127.0.0.1])
 by localhost (dogfood.test.com [127.0.0.1]) (amavisd-new, port 10024)
 with ESMTP id 19256-07 for <bhwang@dogfood.test.com>;
 Tue,  2 Aug 2005 08:03:11 -0700 (PDT)
Received: from test.com (exch1.test.com [10.10.130.37])
	by dogfood.test.com (Postfix) with ESMTP id CAAA736F823
	for <bhwang@dogfood.test.com>; Tue,  2 Aug 2005 08:03:11 -0700 (PDT)
Received: from lab-loadgen02.test.com ([4.78.240.39]) by test.com with Microsoft SMTPSVC(6.0.3790.211);
	 Tue, 2 Aug 2005 08:08:26 -0700
Received: from nez-perce.test.com (nez-perce.test.com [192.93.2.78])
	by lab-loadgen02.test.com (Postfix) with ESMTP id 019BB810038
	for <bhwang@test.com>; Tue,  2 Aug 2005 08:08:06 -0700 (PDT)
Received: from test1.com (test1.com [128.93.8.37])
	by nez-perce.test.com (8.13.0/8.13.0) with ESMTP id j72F3L8D007391;
	Tue, 2 Aug 2005 17:03:22 +0200
Received: from test1.com (localhost [127.0.0.1])
	by test1.com (Postfix) with ESMTP id 36A20BC21;
	Tue,  2 Aug 2005 17:03:20 +0200 (CEST)
X-Original-To: testlist@test1.com
Delivered-To: testlist@test1.com
Received: from concorde.test.com (concorde.test.com [192.93.2.39])
	by test1.com (Postfix) with ESMTP id 1E38ABBD7
	for <testlist@test1.com>; Tue,  2 Aug 2005 17:03:18 +0200 (CEST)
Received: from pauillac.test.com (pauillac.test.com [128.93.11.35])
	by concorde.test.com (8.13.0/8.13.0) with ESMTP id j72F3HBk016791
	for <testlist@test1.com>; Tue, 2 Aug 2005 17:03:17 +0200
Received: from nez-perce.test.com (nez-perce.test.com [192.93.2.78]) by
	pauillac.test.com (8.7.6/8.7.3) with ESMTP id RAA18021 for
	<testlist@pauillac.test.com>;
	Tue, 2 Aug 2005 17:03:17 +0200 (MET DST)
Received: from biscayne-one-station.mit.edu (BISCAYNE-ONE-STATION.TEST.EDU
	[127.0.0.1])
	by nez-perce.test.com (8.13.0/8.13.0) with ESMTP id j72F3FPX007366
	(version=TLSv1/SSLv3 cipher=DHE-RSA-AES256-SHA bits=256 verify=NO)
	for <testlist@test.com>; Tue, 2 Aug 2005 17:03:16 +0200
Received: from outgoing.mit.edu (OUTGOING-AUTH.TEST.EDU [18.7.22.103])
	by biscayne-one-station.mit.edu (8.12.4/8.9.2) with ESMTP id
	j72F3DIt015549; Tue, 2 Aug 2005 11:03:13 -0400 (EDT)
Received: from all-night-tool.abc.com (ALL-NIGHT-TOOL.TEST.EDU [127.0.0.1])
	(authenticated bits=56) (User authenticated as jfc@ATHENA.TEST.EDU)
	by outgoing.mit.edu (8.13.1/8.12.4) with ESMTP id j72F369M029073
	(version=TLSv1/SSLv3 cipher=DHE-RSA-AES256-SHA bits=256 verify=NOT);
	Tue, 2 Aug 2005 11:03:06 -0400 (EDT)
Received: (from jfc@localhost) by all-night-tool.mit.edu (8.12.9)
	id j72F35hR011108; Tue, 2 Aug 2005 11:03:05 -0400 (EDT)
Message-Id: <200508021503.j72F35hR011108@all-night-tool.mit.edu>
To: Ville-Testme Keinonen <will@testme.om>
Subject: Re: [Caml-list] Function Inlining
In-Reply-To: Your message of "Tue, 02 Aug 2005 09:44:29 +0300."
	<42EF164D.1010201@testm.com> 
Date: Tue, 02 Aug 2005 11:03:05 -0400
From: John test <jfc@TEST.EDU>
X-Scanned-By: MIMEDefang 2.42
X-Miltered: at nez-perce with ID 42EF8B39.003 by Joe's j-chkmail (http://j-chkmail.ensmp.fr)!
X-Miltered: at concorde with ID 42EF8B35.000 by Joe's j-chkmail
	(http://j-chkmail.ensmp.fr)!
X-Miltered: at nez-perce with ID 42EF8B33.001 by Joe's j-chkmail
	(http://j-chkmail.ensmp.fr)!
X-Spam: no; 0.00; testlist:01 inlining:01 ocaml:01 inlining:01 rec:01 ocaml:01
	transforming:01 compiler:01 computed:01 pointer:01 stack:01
	stack:01 ocamlopt:01 runtime:01 pointers:01 
Cc: testlist@test.com
X-BeenThere: testlist@test1.com
X-Mailman-Version: 2.1.5
Precedence: list
List-Id: Caml users' mailing list <testlist.test1.com>
List-Unsubscribe: <http://test1.com/cgi-bin/mailman/listinfo/testlist>, 
	<mailto:testlist-request@test1.com?subject=unsubscribe>
List-Post: <mailto:testlist@test1.com>
List-Help: <mailto:testlist-request@test1.com?subject=help>
List-Subscribe: <http://test1.com/cgi-bin/mailman/listinfo/testlist>,
	<mailto:testlist-request@test1.com?subject=subscribe>
Sender: testlist-bounces@test1.com
Errors-To: testlist-bounces@test1.com
X-OriginalArrivalTime: 02 Aug 2005 15:08:26.0326 (UTC) FILETIME=[086C8F60:01C59774]
X-Virus-Scanned: amavisd-new at zimbra.com
X-Spam-Status: No, hits=-2.599 tagged_above=-10 required=6.6 autolearn=ham
 tests=[BAYES_00=-2.599]
X-Spam-Level: 


> You're probably running into restrictions other than size that OCaml has 
> 
> Getting rid of these restrictions could potentially improve OCaml code 
> generation considerably, but as far as I can tell, that would require 
> some additional features in the code generation such as sharing 
> structured constants, explicitly transforming tail calls to loops etc.

I have been working on part of this.

My 64 bit SPARC code generator produces bad assembly code when
nested (not top level) module named Tkintf containing hundreds of
values.  The code generated to initialize Tk.Tkintf looks like:

	1. compute the hundreds of values to be stored in the Tkintf module

about 256 values.  (Because ocamlopt does not use register windows
it is limited to a 2 kilobyte stack frame.)  The assembler fails
with address offset out of range errors.

compute at runtime the majority of module values which are constant,
either integer constants or pointers to statically allocated blocks.

I have been experimenting with making both constant closures and
constant initializers into the data section.  So given a module like

	let x = 1 let y = (1,2,3) let rec f x = ... and g x = ...

the assembly code would look like (with tag values omitted for clarity):

	.data
L1:	# begin three value tuple
	.word	3	# integer 1
	.word	5	# integer 2
	.word	7	# integer 3
L2:	# begin block describing mutually recursive functions f and g
	.word	1	# f arity
	.word	f	# pointer to function f
	.word	1	# g arity
	.word	g	# pointer to function g
module:
	.word	3	# integer 1
	.word	L1	# pointer to (1,2,3)
	.word	L2	# pointer to closure for f
	.word	L2+8	# pointer to closure for g

Values not computable at compile time cause a .skip directive and the
module entry code computes the initial value as in the current compiler.

This solves the stack overflow problem.  I'm not convinced that
the asmcomp phase of the compiler is the right place to do this
optimization.  Perhaps it should be moved to the intermediate

(This is more than just optimizing the performance of code that is
executed once.  For TK a substantial fraction of the code size is
the module entry point.  Also, a few jobs ago I cut the startup time
of a product I worked on by several seconds by optimizing the dynamic
loading process, which is similarly a one time act.)

_______________________________________________
Caml-list mailing list. Subscription management:
EOF
#
# Execution
#
current.action = [    
  p(mimap.method('login'),testAccount.name,testAccount.password),
  p(mimap.method('create'),"INBOX/appendnegative"),  
  p(mimap.method('select'),"INBOX/appendnegative"),  
  
  v(
    p(mimap.method('append'),"INBOX/appendnegative", 'hello world', ['JUNK'], Time.now)
  ) { |caller, data|
    caller.pass = (data.class == Net::IMAP::TaggedResponse) && 
    (data.name == "OK")         
  },
  
  v(
    p(mimap.method('append'),"INBOX/appendnegative", 'hello world', [:Draft], Time.now)
  ) { |caller, data|
    caller.pass = (data.class == Net::IMAP::TaggedResponse) && 
    (data.name == "OK")         
  },
  
  v(
    p(mimap.method('append'),"INBOX/appendnegative", message, [:Draft], Time.now)
  ) { |caller, data|
    caller.pass = (data.class == Net::IMAP::TaggedResponse) && 
    (data.name == "OK")         
  },
  
  v( 
    p(mimap.method('fetch'), 1..3, ['FLAGS', 'INTERNALDATE', 'RFC822.SIZE', 'ENVELOPE'])
  ) { |caller, data|
    result = [[:Recent, '$Junk','Junk'], [:Draft, :Recent], [:Draft, :Recent]].inject([true, 0]) do |sum, n|
      sum[0] = sum[0] && (data[sum[1]].class == Net::IMAP::FetchData) &&
      (data[sum[1]].seqno == sum[1]+1) &&
      (data[sum[1]].attr['FLAGS'].to_set == (Set.new n))  
      sum[1] += 1          
      sum 
    end
    caller.pass = result[0] 
  },
  
  #bug 58753 - 0 length append should return BAD
  v(
    p(mimap.method('append'),"INBOX/appendnegative", "", [:Draft], Time.now)
  ) { |caller, data|
    caller.pass = (data.class == Net::IMAP::BadResponseError) 
  },
  
  p(mimap.method('delete'),"INBOX/appendnegative"),    
  p(mimap.method('logout')),
]

#
# Tear Down
#
current.teardown = [      
  p(mimap.method('disconnect')),  
  DeleteAccount.new(testAccount.name)
]

if($0 == __FILE__)
  require 'engine/simple'
  testCase = Model::TestCase.instance   
  Engine::Simple.new(Model::TestCase.instance).run  
end 
