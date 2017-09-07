#!/usr/bin/ruby -w
#
# $File$
# $DateTime$
#
# $Revision$
# $Author$
#
# 2007 Zimbra
#
#
# Verification logic for imap protocol
#

if($0 == __FILE__)
  $:.unshift(File.join(Dir.getwd,"src","ruby")) #append library path
end

require "action/block"
require "action/verify"
require "action/proxy"
require "set"
require "time"

if (RUBY_VERSION > "1.9")
  module OpenSSL
    module SSL
      remove_const :VERIFY_PEER
    end
  end
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end

class Net::IMAP
  # Expose internal socket very dangerous to use!
  def getSocket
    @sock
  end

  # Force thread kill on disconnect
  # This is to fix hanging issue on disconnect
  def disconnect
      @sock.shutdown unless @usessl
      @receiver_thread.join(60).nil? && @receiver_thread.kill
      @sock.close
  end

  if RUBY_VERSION < "1.8.6" or RUBY_VERSION > "1.9"
      def send_literal(str)
        put_string("{" + str.length.to_s + "}" + CRLF)
        @continuation_bad = false
        @continuation_request_arrival.wait
        put_string(str) unless @continuation_bad
      end
  end

  # Receive response
   def receive_responses
      while true
        begin
          resp = get_response
        rescue Exception
          @sock.close
          @client_thread.raise($!)
          break
        end
        break unless resp
        begin
          synchronize do
            case resp
            when TaggedResponse
              @tagged_responses[resp.tag] = resp
              if(RUBY_VERSION < "1.8.6" or RUBY_VERSION > "1.9")
                @tagged_response_arrival.broadcast
              else
                @response_arrival.broadcast
              end

              if (RUBY_VERSION < "1.8.6" or RUBY_VERSION > "1.9") && (resp.name == "BAD" || resp.name == "NO") #need to flush back patching ruby bug on continuation
                 @continuation_bad = true
                 @continuation_request_arrival.signal
              end

              if resp.tag == @logout_command_tag
                return
              end
            when UntaggedResponse
              record_response(resp.name, resp.data)
              if resp.data.instance_of?(ResponseText) &&
                  (code = resp.data.code)
                record_response(code.name, code.data)
              end
              #if resp.name == "BYE" && @logout_command_tag.nil?
              #  @sock.close
              #  return
              #end
            when ContinuationRequest
              if(RUBY_VERSION < "1.8.6" or RUBY_VERSION > "1.9" )
                @continuation_request_arrival.signal
              else
                @continuation_request = resp
                @response_arrival.broadcast
              end
            end
            @response_handlers.each do |handler|
              handler.call(resp)
            end
          end
        rescue Exception
          @client_thread.raise($!)
        end
      end
    end

  # Enable command
  def enable(*keys)
    synchronize do
      send_command("ENABLE", keys.join(' '))
    end
  end

  # Extend search
  def esearch_internal(cmd, keys, charset)
    if keys.instance_of?(String)
      keys = [RawData.new(keys)]
    else
      normalize_searching_criteria(keys)
    end
    synchronize do
      if charset
        send_command(cmd, "CHARSET", charset, *keys)
      else
        send_command(cmd, *keys)
      end
      #puts YAML.dump(@responses)
      return @responses.delete("ESEARCH")[-1] rescue ""
    end
  end

  def esearch(keys, charset = nil)
    return esearch_internal("SEARCH", keys, charset)
  end

  def elist(refname, mailbox, poptions = nil, pret = nil)
    synchronize do
      mArgs = []
      mArgs.push(poptions) if poptions
      mArgs.push(refname)
      mArgs.push(mailbox)
      if pret
        mArgs.push("RETURN")
        mArgs.push(pret)
      end
      send_command("LIST", *mArgs)
      return @responses.delete("LIST")
    end
  end

  def xlist(refname, mailbox)
      synchronize do
        send_command("XLIST", refname, mailbox)
        return @responses.delete("XLIST")
      end
  end

  MailboxListE = Struct.new(:attr, :delim, :name, :children)

  def mappend(mailbox, messages, flags = nil, date_time = nil)
    args = []
    messages.each do |x|
      if flags
        args.push(flags)
      end
      args.push(date_time) if date_time
      args.push(Literal.new(x))
    end
    send_command("APPEND", mailbox, *args)
  end

end
# Patch to work with 1:*
class Net::IMAP::MessageSet
  def format_internal(data)
      case data
      when /\d+:\*/
        return data
      when "*"
        return data
      when Integer
        ensure_nz_number(data)
        if data == -1
          return "*"
        else
          return data.to_s
        end
      when Range
        return format_internal(data.first) +
          ":" + format_internal(data.last)
      when Array
        return data.collect {|i| format_internal(i)}.join(",")
      when ThreadMember
        return data.seqno.to_s +
          ":" + data.children.collect {|i| format_internal(i).join(",")}
      else
        raise DataFormatError, data.inspect
      end
  end

  def validate
    # do nothing, return nil - for ruby 1.9 compliance (search rusults test)
  end
end
#
# Patch BADCHARSET into the parser
#
class Net::IMAP::ResponseParser
  def mailbox_list
    attr = flag_list
    match(T_SPACE)
    token = match(T_QUOTED, T_NIL)
    if token.symbol == T_NIL
     delim = nil
    else
     delim = token.value
    end
    match(T_SPACE)
    name = astring
    token = lookahead
    if token.symbol == T_CRLF
     return Net::IMAP::MailboxList.new(attr, delim, name)
    else
     match(T_SPACE)
     match(T_LPAR)
     match(T_QUOTED, T_ATOM)
     match(T_SPACE)
     children= flag_list
     match(T_RPAR)
      return Net::IMAP::MailboxListE.new(attr, delim, name, children)
    end
  end

  def response_untagged
    match(T_STAR)
    match(T_SPACE)
    token = lookahead
    if token.symbol == T_NUMBER
      return numeric_response
    elsif token.symbol == T_ATOM
      case token.value
      when /\A(?:OK|NO|BAD|BYE|PREAUTH)\z/ni
        return response_cond
      when /\A(?:FLAGS)\z/ni
        return flags_response
      when /\A(?:XLIST|LIST|LSUB)\z/ni
        return list_response
      when /\A(?:QUOTA)\z/ni
        return getquota_response
      when /\A(?:QUOTAROOT)\z/ni
        return getquotaroot_response
      when /\A(?:ACL)\z/ni
        return getacl_response
      when /\A(?:SEARCH|SORT)\z/ni
        return search_response
      when /\A(?:THREAD)\z/ni
        return thread_response
      when /\A(?:STATUS)\z/ni
        return status_response
      when /\A(?:CAPABILITY)\z/ni
        return capability_response
      else
        return text_response
      end
    else
      parse_error("unexpected token %s", token.symbol)
    end
  end

  def resp_text_code
    @lex_state = EXPR_BEG
    match(T_LBRA)
    token = match(T_ATOM)
    name = token.value.upcase
    case name
    when /\A(?:ALERT|BADCHARSET|NOMODSEQ|PARSE|READ-ONLY|READ-WRITE|TRYCREATE)\z/n
      result = Net::IMAP::ResponseCode.new(name, nil)
    when /\A(?:PERMANENTFLAGS)\z/n
      match(T_SPACE)
      result = Net::IMAP::ResponseCode.new(name, flag_list)
    when /\A(?:UIDVALIDITY|UIDNEXT|UNSEEN)\z/n
      match(T_SPACE)
      result = Net::IMAP::ResponseCode.new(name, number)
    else
      match(T_SPACE)
      @lex_state = EXPR_CTEXT
      token = match(T_TEXT)
      @lex_state = EXPR_BEG
      result = Net::IMAP::ResponseCode.new(name, token.value)
    end
    match(T_RBRA)
    @lex_state = EXPR_RTEXT
    return result
  end

  def msg_att(n = "not defined")# adding 'n' with default value to comply with ruby 2.0.0
    match(T_LPAR)
    attr = {}
    while true
      token = lookahead
      case token.symbol
      when T_RPAR
        shift_token
        break
      when T_SPACE
        shift_token
        next # token = lookahead # change since ruby 2.0.0
      end
      case token.value
      when /\A(?:ENVELOPE)\z/ni
        name, val = envelope_data
      when /\A(?:FLAGS)\z/ni
        name, val = flags_data
      when /\A(?:INTERNALDATE)\z/ni
        name, val = internaldate_data
      when /\A(?:RFC822(?:\.HEADER|\.TEXT)?)\z/ni
        name, val = rfc822_text
      when /\A(?:RFC822\.SIZE)\z/ni
        name, val = rfc822_size
      when /\A(?:BODY(?:STRUCTURE)?)\z/ni
        name, val = body_data
      when /\A(?:BINARY(?:STRUCTURE)?)\z/ni
        name, val = body_data
      when /\A(?:UID)\z/ni
        name, val = uid_data
      when /\A(?:MODSEQ)\z/ni
        name, val = modseq_data
      else
        parse_error("unknown attribute `%s'", token.value, n) #added 'n' to comply with ruby 2.0.0
      end
      attr[name] = val
    end
    return attr
  end

  def modseq_data
    token = match(T_ATOM)
    name = token.value.upcase
    match(T_SPACE)
    return name, modseq
  end

  def modseq
    match(T_LPAR)
    token = lookahead
    case token.symbol
    when T_RPAR
      shift_token
      return nil
    when T_NUMBER
      shift_token
      data = token.value
      match(T_RPAR)
      return data
    else
      parse_error("unexpected token %s", token.symbol)
    end
  end

  # patch for ruby 1.9.3 and up
  # see bug https://bugs.ruby-lang.org/issues/8281
  def getacl_response
    token = match(T_ATOM)
    name = token.value.upcase
    match(T_SPACE)
    mailbox = astring
    data = []
    token = lookahead
    if token.symbol == T_SPACE
      shift_token
      while true
        token = lookahead
        case token.symbol
        when T_CRLF
          break
        when T_SPACE
          shift_token
        end
        user = astring
        match(T_SPACE)
        rights = astring
        ##XXX data.push([user, rights])
        data.push(Net::IMAP::MailboxACLItem.new(user, rights))
      end
    end
    return Net::IMAP::UntaggedResponse.new(name, data, @str)
  end

end


# Change Message Set to allow $ part of save search extension
#
class Net::IMAP::MessageSet
  def format_internal(data)
    case data
    when "*"
      return data
    when "$"
      return data
    when /:/
      return data
    when Integer
      ensure_nz_number(data)
      if data == -1
        return "*"
      else
        return data.to_s
      end
    when Range
      return format_internal(data.first) +
        ":" + format_internal(data.last)
    when Array
      return data.collect {|i| format_internal(i)}.join(",")
    when ThreadMember
      return data.seqno.to_s +
        ":" + data.children.collect {|i| format_internal(i).join(",")}
    else
      raise DataFormatError, data.inspect
    end
  end
end

module Action

  module IMAP
    @@badString = 'parse error'

    def IMAP.badString
      @@badString
    end

    def IMAP.badString=(data)
      @@badString = data
    end

    def IMAP.noResponseError(checkString)
      proc { |mcaller, data|
        mcaller.pass = (data.class == Net::IMAP::NoResponseError) &&
        (data.message.include?(checkString))
      }
    end

    def IMAP.badResponseError(checkString)
      proc { |mcaller, data|
        mcaller.pass = (data.class == Net::IMAP::BadResponseError) &&
        (data.message.include?(checkString))
      }
    end

    def IMAP.parseError
      proc { |mcaller, data|
        mcaller.pass = (data.class == Net::IMAP::BadResponseError) &&
        (data.message.include?(Action::IMAP.badString))
      }
    end

    def IMAP.fetchParseError
      proc { |mcaller, data|
        mcaller.pass = (data.class == Net::IMAP::BadResponseError) &&
        (data.message.include?('parse error'))
      }
    end


    #Bunch of error checking code
    CopyFailed = noResponseError('COPY failed') unless defined?(CopyFailed)
    CreateFailed = noResponseError('CREATE failed') unless defined?(CreateFailed)
    DeleteFailed = noResponseError('DELETE failed') unless defined?(DeleteFailed)
    DonotExist = noResponseError('no longer exist') unless defined?(DonotExist)
    ExamineFailed= noResponseError('EXAMINE failed') unless defined?(ExamineFailed)
    GetQuotaFailed = noResponseError('GETQUOTA failed') unless defined?(GetQuotaFailed)
    GetQuotaRootFailed = noResponseError('GETQUOTAROOT failed') unless defined?(GetQuotaRootFailed)
    RenameFailed= noResponseError('RENAME failed') unless defined?(RenameFailed)
    SelectFailed= noResponseError('SELECT failed') unless defined?(SelectFailed)
    SetQuotaFailed = noResponseError('SETQUOTA failed') unless defined?(SetQuotaFailed)
    StatusFailed = noResponseError('STATUS failed') unless defined?(StatusFailed)
    SubscribeFailed = noResponseError('SUBSCRIBE failed') unless defined?(SubscribeFailed)
    MustNotInAuth = noResponseError('must be in NOT AUTHENTICATED stat') unless defined?(MustNotInAuth)
    MustInSelect = noResponseError('must be in SELECTED state') unless defined?(MustInSelect)
    MustInAuthSelect = noResponseError('must be in AUTHENTICATED or SELECTED state') unless defined?(MustInAuthSelect)
    ReadOnly = noResponseError('mailbox selected READ-ONLY') unless defined?(ReadOnly)

    InvalidUTF7 = badResponseError('UTF-7') unless defined?(InvalidUTF7)
    Nonstorable = badResponseError('non-storable') unless defined?(Nonstorable)
    InvalidFlag = badResponseError('invalid flag') unless defined?(InvalidFlag)
    ParseError = parseError unless defined?(ParseError)
    FetchParseError = fetchParseError unless defined?(FetchParseError)
    UnindexedHeader = noResponseError('unindexed header') unless defined?(UnindexedHeader)

    EmptyArray = proc do |mcaller, data|
      mcaller.pass = (data.class == Array) && (data.size == 0)
    end unless defined?(EmptyArray)

    def IMAP.dupResponse(responses)
      rhash = responses.dup
      responses.each do |key, value|
        rhash[key] = value.dup
      end
      rhash
    end

    def IMAP.genFetchAction(imapargv, testAccount, mailbox, x)
      v(cb("Fetch operation #{x[0]}") do
            result = nil
            begin
              n = Net::IMAP.new(*imapargv)
              n.login(testAccount.name, testAccount.password)
              n.select(mailbox)
              result = FetchVerify.new(n, 1..1, x[0], x[1]).run
            rescue => error
              eresult = Object.new
              class <<eresult
                attr :pass, true
                attr :msg, true
                attr :data, true
              end
              eresult.pass = false
              eresult.msg = error
              eresult.data = result
              result = eresult
            ensure
              if(n)
                n.logout
                n.disconnect
              end
            end
            result
        end) do |mcaller, data|
          mcaller.pass = data.pass
      end
    end

    def IMAP.genSearchAction(m, testAccount, message, msymble, mname, mname2)
      mailbox = "INBOX/"+mname
      [
        p(m.method('login'),testAccount.name,testAccount.password),
        p(m.method('create'),mailbox),
        cb("Create 20 messages using append") {
          1.upto(20) { |i|
            m.append(mailbox, message.gsub(/REPLACEME/,i.to_s),[], Time.now)
          }
          "Done"
        },
        p(m.method('examine'), mailbox),
        SearchVerify.new(m, [mname], &IMAP::EmptyArray),
        SearchVerify.new(m, [mname2], (1..20).to_a),
        p(m.method('select'), mailbox),
        p(m.method('store'), 1, "+FLAGS",[msymble]),
        {
          [mname] => (z = [1]),
          [mname2] => (y = (2..20).to_a),
          ["NOT", mname] => y,
          ["NOT", mname2] => z,
          ["NOT", "NOT", mname] => z,
          ["NOT", "NOT", mname2] => y
        }.sort.map do |x|
           SearchVerify.new(m, x[0], x[1])
        end,
        p(m.method('store'), 1..10, "+FLAGS",[msymble]),
        {
          [mname] => (y = (1..10).to_a),
          [mname2] => (z = (11..20).to_a),
          ["NOT", mname] => (11..20).to_a,
          ["NOT", mname2] => y,
          ["NOT", "NOT", mname] => y,
          ["NOT", "NOT", mname2] => z
        }.sort.map do |x|
           SearchVerify.new(m, x[0], x[1])
        end,

        p(m.method('store'), 1..10, "-FLAGS",[msymble]),
        SearchVerify.new(m, [mname], &IMAP::EmptyArray),
        SearchVerify.new(m, [mname2], (1..20).to_a),
        UidsearchVerify.new(m, [mname], &IMAP::EmptyArray),
        UidsearchVerify.new(m, [mname2], 20),
        p(m.method('delete'),mailbox)
      ]
    end
  end

  class PlainAuthenticator
    def process(data)
      return "#{@user}#{0.chr}#{@credential}#{0.chr}#{@password}"
    end

    private

    def initialize(user, credential, password)
      @user = user
      @credential = credential
      @password = password
    end
  end

  class XZimbraAuthenticator
    def process(data)
      return "#{@user}#{0.chr}#{@credential}#{0.chr}#{@token}"
    end

    private

    def initialize(user, credential, token)
      @user = user
      @credential = credential
      @token = token
    end
  end


  class AppendVerify < Action::Verify
    def initialize(index, flags, mtime, mimap)
      @instruction = proc do
        begin
          mimap.fetch(index, 'ALL')
        rescue Net::IMAP::ResponseParseError => e
          e.message
        end
      end

      super(cb("Fetch for Append", &@instruction)) { |caller, data|
        caller.pass = (data[0].class == Net::IMAP::FetchData) &&
        (data[0].seqno == index) &&
        (data[0].attr['FLAGS'].to_set == (Set.new flags)) &&
        (Time.parse(data[0].attr['INTERNALDATE']) == mtime)
        if(!caller.pass)
          class << caller
            attr :ptime, true
            attr :internaldate, true
          end
          caller.ptime = mtime
          caller.internaldate = data[0].attr['INTERNALDATE']
        end
      }
    end
  end

  class CapabilityVerify < Action::Verify
    @@compareSet = ['IMAP4REV1', 'AUTH=PLAIN', 'ACL', 'BINARY', 'CATENATE', 'CONDSTORE', 'CHILDREN', 'ESEARCH', 'ESORT', 'ID',
          'IDLE', 'LIST-EXTENDED', 'LITERAL+', 'LOGIN-REFERRALS', 'MULTIAPPEND', 'NAMESPACE', 'QUOTA', 'RIGHTS=EKTX', 'SORT',
          'SASL-IR', 'UIDPLUS', 'UNSELECT', 'WITHIN', 'QRESYNC', 'SEARCHRES', 'ENABLE', 'THREAD=ORDEREDSUBJECT', 'I18NLEVEL=1', 'XLIST', 'LIST-STATUS'].to_set
    def initialize(mimap)
      super(proxy(mimap.method('capability'))) { |mcaller, data|
        mcaller.pass = (data.to_set == @@compareSet)
        if(!mcaller.pass)
          class << self
            attr :difference, true
          end
          self.difference = (@@compareSet|data)-(@@compareSet&data)
        end
      }
    end

    def CapabilityVerify.addCapability(*data)
      @@compareSet.merge(data)
    end
    def CapabilityVerify.removeCapability(*data)
      @@compareSet.subtract(data)
    end

  end

   class CapabilityVerifyNoAuth < Action::Verify
    @@compareSet = ['IMAP4REV1', 'ACL', 'BINARY', 'CATENATE', 'CONDSTORE', 'CHILDREN', 'ESEARCH', 'ESORT', 'ID',
          'IDLE', 'LIST-EXTENDED', 'LITERAL+', 'LOGIN-REFERRALS', 'MULTIAPPEND', 'NAMESPACE', 'QUOTA', 'RIGHTS=EKTX', 'SORT',
          'SASL-IR', 'UIDPLUS', 'UNSELECT', 'WITHIN', 'QRESYNC', 'SEARCHRES', 'ENABLE', 'THREAD=ORDEREDSUBJECT', 'I18NLEVEL=1', 'XLIST', 'LIST-STATUS'].to_set
    def initialize(mimap)
      super(proxy(mimap.method('capability'))) { |mcaller, data|
        mcaller.pass = (data.to_set == @@compareSet)
        if(!mcaller.pass)
          class << self
            attr :difference, true
          end
          self.difference = (@@compareSet|data)-(@@compareSet&data)
        end
      }
    end

    def CapabilityVerifyNoAuth.addCapability(*data)
      @@compareSet.merge(data)
    end
    def CapabilityVerifyNoAuth.removeCapability(*data)
      @@compareSet.subtract(data)
    end

  end

  class Complete < Action::Verify
    def initialize(mimap, mname, check_string, *myargv, &myblock)
      if(block_given?) then
        super(proxy(mimap, mname, *myargv, &myblock))
      else
        super(proxy(mimap, mname, *myargv)) { |mcaller, data|
          mcaller.pass = (data.class == Net::IMAP::TaggedResponse) &&
            (data.data.class == Net::IMAP::ResponseText) &&
            (data.data.text.include?(check_string))
        }
      end
    end
  end

  class AuthVerify < Complete
    def initialize(mimap, *myargv, &myblock)
      if(block_given?) then
        super(mimap, 'authenticate', *myargv, &myblock)
      else
        super(mimap, 'authenticate', *myargv)
      end
    end
  end

  class CheckVerify < Complete
    def initialize(mimap, &myblock)
      if(block_given?) then
        super(mimap, 'check', 'CHECK completed', &myblock)
      else
        super(mimap, 'check', 'CHECK completed')
      end
    end
  end

  class CloseVerify < Complete
    def initialize(mimap, &myblock)
      if(block_given?) then
        super(mimap, 'close', 'CLOSE completed', &myblock)
      else
        super(mimap, 'close', 'CLOSE completed')
      end
    end
  end

  class CopyVerify < Complete
    def initialize(mimap, *myargv, &myblock)
      if(block_given?) then
        super(mimap, 'copy', 'COPY completed', *myargv, &myblock)
      else
        super(mimap, 'copy', 'COPY completed', *myargv)
      end
    end
  end

  class CreateVerify < Complete
    def initialize(mimap, *myargv, &myblock)
      if(block_given?) then
        super(mimap, 'create', 'CREATE completed', *myargv, &myblock)
      else
        super(mimap, 'create', 'CREATE completed', *myargv)
      end
    end
  end

  class DeleteVerify < Complete
    def initialize(mimap, *myargv, &myblock)
      if(block_given?) then
        super(mimap, 'delete', 'DELETE completed', *myargv, &myblock)
      else
        super(mimap, 'delete', 'DELETE completed', *myargv)
      end
    end
  end

  class ExamineVerify < Action::Verify

    def initialize(mimap, mailbox, flags = [:Deleted, :Draft, :Flagged, :Seen], &myblock)

      if(block_given?)
        @myblock = myblock
      else
        @myblock = proc { |mcaller, data |
          mcaller.pass = (data['FLAGS'].flatten.to_set.superset?(flags.to_set))
        }
      end

      @instruction = proc do
        mimap.examine(mailbox)
        IMAP.dupResponse(mimap.responses)
      end

      super(cb("Examine Verify '#{mailbox}'", &@instruction), &@myblock)
    end
  end

  class ExpungeVerify < Action::Verify

    def initialize(mimap, mailbox, datacheck = {}, &myblock)
      @datacheck = datacheck

      if(block_given?)
        @mybock = myblock
      else
        @mybock = proc { |mcaller, data|  #the data is in hash format
          equal = true
          @datacheck.each do | key, value |
            if(not data.has_key?(key))
              equal = false
            else
              equal = equal && (data[key] == value)
            end
          end
          mcaller.pass = equal
        }
      end

      @instruction = proc do
        mimap.expunge
        IMAP.dupResponse(mimap.responses)
      end

      super(cb("Expunge Verify '#{mailbox}'", &@instruction), &@mybock)
    end
  end

  class FetchVerify < Action::Verify
    def initialize(mimap, range, condition, check = '.', &myblock)

      if(block_given?)
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|  #the data is in hash format
          mcaller.pass = (data.class == Array) &&
            data.inject(true) do |meta, obj|
              meta && (not (obj.attr.values.join =~ /#{check.to_s}/).nil?)
            end
        end
      end

      @instruction = proc do
        outstring = range.to_s.gsub(/\.\./, ':')
        begin
          mimap.fetch(range, condition)
        rescue Net::IMAP::ResponseParseError => e
          e.message
        end
      end

      super(cb("Fetch Verify '#{range} #{condition}'", &@instruction), &@myblock)
    end
  end

  class IDVerify < Action::Verify


    def initialize(mimap, description = '', marg = 'NIL', check = ['NAME','Zimbra','VERSION','RELEASE'],
      &myblock)


      if(block_given?)
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|
          mcaller.pass = check.inject(true) do |meta, obj|
            meta && (not (data[1] =~ /#{obj}/).nil?)
          end #mcaller
        end #myblock
      end #if

      @instruction = cb("ID #{description}") {
        [mimap.method('send_command').call("ID #{marg}"), mimap.responses['ID'][-1]]
      }

      super(@instruction, &@myblock)
    end #initalize

  end #class

  class List < Action::Verify

    def initialize(mimap, root, tree, datacheck = [], instruction = proc {}, &myblock)
      @datacheck = datacheck
      @root = root
      @tree = tree

      if(block_given?)
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|  #the data is in hash format
          #puts YAML.dump(data)
          if data.class != Array
            mcaller.pass = false
          elsif not data.inject(true) { |memo, obj | memo & (obj.class == Net::IMAP::MailboxList) }
            mcaller.pass = false
          else
            flagArray = [*data.map { |obj| [obj.name, obj.attr] }]
            mcaller.pass =  flagArray.to_set.superset?(@datacheck.to_set)
          end
        end
      end

      @instruction = instruction
      super(cb("List Verify #{@root} #{@tree}", &@instruction), &@myblock)
    end
  end

  class ListVerify < List
    def initialize(mimap, root, tree, datacheck = [], &myblock)
      super(mimap, root, tree, datacheck, proc { mimap.list(root, tree) }, &myblock)
    end
  end

  class LoginVerify < Complete
    def initialize(mimap, *myargv, &myblock)
      if(block_given?) then
        super(mimap, 'login', 'LOGIN completed', *myargv, &myblock)
      else
        super(mimap, 'login', 'LOGIN completed', *myargv)
      end
    end
  end

  class LogoutVerify < Complete
    def initialize(mimap, *myargv, &myblock)
      if(block_given?) then
        super(mimap, 'logout', 'completed', *myargv, &myblock)
      else
        super(mimap, 'logout', 'completed', *myargv)
      end
    end

  end

  class LsubVerify < List
    def initialize(mimap, root, tree, datacheck = [], &myblock)
      super(mimap, root, tree, datacheck, proc { mimap.lsub(root, tree) }, &myblock)
    end
  end

  class NamespaceVerify < Action::Verify

    def initialize(mimap, description = '', check = ['NIL', '"', '/'],
      &myblock)

      if(block_given?)
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|
          mcaller.pass = check.inject(true) do |meta, obj|
            meta && (not (data[1] =~ /#{obj}/).nil?)
          end #mcaller
        end #myblock
      end #if

      @instruction = cb("Namespace #{description}") {
        [mimap.method('send_command').call("NAMESPACE"), mimap.responses['NAMESPACE'][-1]]
      }

      super(@instruction, &@myblock)
    end #initalize
  end #class

  class NoopVerify < Action::Verify
    def initialize(mimap,datacheck={}, &myblock)
      if(block_given?)
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|
          if data.class != Hash
            mcaller.pass = false
          else
            mcaller.pass = true
            datacheck.each do |key, value|
              if(data.has_key?(key))
                mcaller.pass = mcaller.pass && data[key].to_set.superset?(value.to_set)
              else
                mcaller.pass = false
              end
              break if mcaller.pass == false
            end
          end
        end
      end

      @instruction = proc do
        mimap.noop()
        IMAP.dupResponse(mimap.responses)
      end
      super(cb("Noop Verify #{datacheck}", &@instruction), &@myblock)
    end
  end

  class RenameVerify < Complete
    def initialize(mimap, *myargv, &myblock)
      if(block_given?) then
        super(mimap, 'rename', 'RENAME completed', *myargv, &myblock)
      else
        super(mimap, 'rename', 'RENAME completed', *myargv)
      end
    end
  end

  class SearchVerify < Action::Verify
    def initialize(mimap, flags, ids = [], &myblock)
      if(block_given?)
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|
          if(data.nil? || (data.size == 0))
            mcaller.pass = (ids.size == 0)
          else
            mcaller.pass =  (data.class == Array) &&
              data.to_set.superset?(ids.to_set)
          end
          if(not mcaller.pass)
            class << mcaller
              attr :pflags, true
              attr :pids, true
            end
            mcaller.pflags = flags
            mcaller.pids = ids
          end
        end
      end

      textString = if(flags.class == Array)
        flags.join(' ')
      else
        flags
      end

      @instruction = cb("Search Verify [#{textString}] [#{ids.join(' ')}]") do
        mimap.search(flags)
      end
      super(@instruction, &@myblock)
    end
  end

  class SelectVerify < Action::Verify
    def initialize(mimap, mailbox, &myblock)

      if(block_given?)
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|
          mcaller.pass = (data.class == Net::IMAP::TaggedResponse) &&
            (data.data.class == Net::IMAP::ResponseText) &&
            (data.data.code.class == Net::IMAP::ResponseCode) &&
            (data.data.code.name == 'READ-WRITE')
        end
      end

      @instruction = cb("SelectVerify #{mailbox}") do
        mimap.select(mailbox)
      end
      super(@instruction, &@myblock)
    end
  end

  class StatusVerify < Action::Verify
    def initialize(mimap, mailbox, flags, &myblock)

      if(block_given?)
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|
          mcaller.pass =  flags.inject(true) { |check, flag| check && data.include?(flag) }
        end
      end

      @instruction = cb("StatusVerify #{mailbox} #{flags}") do
        mimap.status(mailbox, flags)
      end
      super(@instruction, &@myblock)
    end
  end

  class StoreVerify < Action::Verify

    def initialize(mimap, index, setting, flags, cflags = [], &myblock)

      if(block_given?)
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|
          if(data.class != Array)
            mcaller.pass = false
          elsif not data.inject(true) { |memo, obj | memo & (obj.class == Net::IMAP::FetchData) }
            mcaller.pass = false
          else
            cflagset = cflags.to_set
            mcaller.pass = data.inject(true) do |memo, obj|
              memo && obj.attr['FLAGS'].to_set.superset?(cflagset)
            end
          end
        end
      end

      @instruction = cb("Store Verify #{index} #{setting} #{flags}") do
         mimap.store(index, setting, flags)
      end
      super(@instruction, &@myblock)
    end #intialized
  end #class

  class SubscribeVerify < Action::Verify

    def initialize(mimap, mailbox, &myblock)
      if(block_given?) then
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|
          mcaller.pass = (data.class == Array) && data.inject(true) do |memo, object|
            memo && (object.class == Net::IMAP::MailboxList) &&
              (object.name.downcase == mailbox.downcase)
          end
        end
      end

      @instruction = cb("Subscribe mailbox #{mailbox}") do
        mimap.subscribe(mailbox)
        mimap.lsub("", mailbox)
      end
      super(@instruction, &@myblock)
    end

  end

  class UidsearchVerify < Action::Verify
    def initialize(mimap, flags, size = 0, &myblock)
      if(block_given?)
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|
          mcaller.pass =  (data.class == Array) &&
            data.size == size
        end
      end

      textString = if(flags.class == Array)
         flags.join(' ')
      else
         flags
      end

      @instruction = cb("Uid Search Verify [#{textString}] #{size}") do
        mimap.method('uid_search').call(flags)
      end
      super(@instruction, &@myblock)
    end
  end

  class UnselectVerify < Action::Verify

    def initialize(mimap, *myargv, &myblock)

      if(block_given?) then
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|
          mcaller.pass = (data.class == Net::IMAP::TaggedResponse) &&
          (data.name == 'OK') &&
          data.data.text.include?('UNSELECT completed')
        end
      end

      @instruction = cb("Unselect #{myargv.join(' ')}") do
        mimap.method('send_command').call("UNSELECT")
      end
      super(@instruction, &@myblock)
    end
  end

  class UnsubscribeVerify < Action::Verify
    def initialize(mimap, mailbox, &myblock)
      if(block_given?) then
        @myblock = myblock
      else
        @myblock = proc do |mcaller, data|
          if(data[1].nil?)
            mcaller.pass = data[0].nil? || (data[0].size == 1)
          else
            mcaller.pass = (data[1].class == Array) && data[1].inject(true) do |memo, object|
              memo && (object.class == Net::IMAP::MailboxList) &&
                ((object.name.downcase != mailbox.downcase) || (object.attr.to_set.superset?([:Noselect].to_set)))
            end
            mcaller.pass = mcaller.pass && (not data[0].nil?) && (not data[1].size > data[0].size)
          end
          if(not mcaller.pass)
            puts YAML.dump(data)
          end
        end
      end

      @instruction = cb("Unsubscribe mailbox #{mailbox}") do
        before = mimap.lsub("", "*")
        mimap.unsubscribe(mailbox)
        after = mimap.lsub("", "*")
        [before, after]
      end
      super(@instruction, &@myblock)
    end
  end

  class XlistVerify < List
    def initialize(mimap, root, tree, datacheck = [], &myblock)
      super(mimap, root, tree, datacheck, proc { mimap.xlist(root, tree) }, &myblock)
    end
  end

end

if $0 == __FILE__
  require 'test/unit'
  include Action
    # Unit test cases for Proxy
    class Dummy
      attr_reader(:capability, :check, :close, :copy, :create, :delete, :examine, :fetch,
        :list, :login, :noop, :logout, :rename, :search, :select, :status, :store,
        :subscribe, :uid_search)
    end

    class CapabilityVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = CapabilityVerify.new(Dummy.new)
        assert(testOne.class == CapabilityVerify, "Object Creation Test")
      end
    end

    class CheckVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = CheckVerify.new(Dummy.new)
        assert(testOne.class == CheckVerify, "Object Creation Test")
      end
    end

    class CloseVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = CloseVerify.new(Dummy.new)
        assert(testOne.class == CloseVerify, "Object Creation Test")
      end
    end

    class CopyVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = CopyVerify.new(Dummy.new)
        assert(testOne.class == CopyVerify, "Object Creation Test")
      end
    end

    class CreateVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = CreateVerify.new(Dummy.new)
        assert(testOne.class == CreateVerify, "Object Creation Test")
      end
    end

    class DeleteVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = CreateVerify.new(Dummy.new)
        assert(testOne.class == CreateVerify, "Delete Object Creation Test")
      end
    end

    class ExamineVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = ExamineVerify.new(Dummy.new, "dumy")
        assert(testOne.class == ExamineVerify, "Examine Object Creation Test")
      end
    end

    class ExpungeVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = ExpungeVerify.new(Dummy.new ,"dummy")
        assert(testOne.class == ExpungeVerify, "Expunge Object Creation Test")
      end
    end

    class FetchVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = FetchVerify.new(Dummy.new ,"dummy", "dummy2", "dummy3")
        assert(testOne.class == FetchVerify, "Fetch Object Creation Test")
      end
    end

    class IDVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = IDVerify.new(Dummy.new)
        assert(testOne.class == IDVerify, "ID Object Creation Test ")
      end
    end

    class ListVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = ListVerify.new(Dummy.new ,"dummy", "dummy")
        assert(testOne.class == ListVerify, "List Object Creation Test")
      end
    end

    class LoginVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = LoginVerify.new(Dummy.new ,"dummy", "dummy")
        assert(testOne.class == LoginVerify, "Object Creation Test")
      end
    end

    class LogoutVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = LogoutVerify.new(Dummy.new ,"dummy", "dummy")
        assert(testOne.class == LogoutVerify, "Object Creation Test")
      end
    end

    class LsubVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = LsubVerify.new(Dummy.new ,"dummy", "dummy")
        assert(testOne.class == LsubVerify, "Object Creation Test")
      end
    end

    class NamespaceVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = NamespaceVerify.new(Dummy.new)
        assert(testOne.class == NamespaceVerify, "Namespace Object Creation Test ")
      end
    end

    class NoopVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = NoopVerify.new(Dummy.new, [])
        assert(testOne.class == NoopVerify, "Noop Creation Test")
      end
    end

    class RenameVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = RenameVerify.new(Dummy.new, [])
        assert(testOne.class == RenameVerify, "Rename Creation Test")
      end
    end

    class SearchVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = SearchVerify.new(Dummy.new, [], [2,3])
        assert(testOne.class == SearchVerify, "Search Creation Test")
      end
    end

    class SelectVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = SelectVerify.new(Dummy.new, "one/two")
        assert(testOne.class == SelectVerify, "Object Creation Test")
      end

      def testBlock
        testOne = SelectVerify.new(Dummy.new, "one/two") { |caller, data| caller.pass = "hello world" }
        testOne.run
        assert(testOne.pass == "hello world", "Supply block testing")
      end
    end

    class StatusVerifyTest < Test::Unit::TestCase
      def testBasic
        assert(StatusVerify.new(Dummy.new, "one/two", ['yea']).class == StatusVerify)
      end
    end

    class StoreVerifyTest < Test::Unit::TestCase
      def testBasic
        assert(StoreVerify.new(Dummy.new, 1, ["one/two"], ['yea']).class == StoreVerify)
      end
    end

    class SubscribeVerifyTest < Test::Unit::TestCase
      def testBasic
        assert(SubscribeVerify.new(Dummy.new, ['yea']).class == SubscribeVerify)
      end
    end

    class UidsearchVerifyTest < Test::Unit::TestCase
      def testBasic
        testOne = UidsearchVerify.new(Dummy.new, [], 0)
        assert(testOne.class == UidsearchVerify, "UID Search Creation Test")
      end
    end

    class UNselectVerifyTest < Test::Unit::TestCase
      def testBasic
        assert(UnselectVerify.new(Dummy.new, 'whatever').class == UnselectVerify)
      end
    end


    class UnsubscribeVerifyTest < Test::Unit::TestCase
      def testBasic
        assert(UnsubscribeVerify.new(Dummy.new, ['yea']).class == UnsubscribeVerify)
      end
    end

    class SearchActionTest < Test::Unit::TestCase
      def testBasic
#      IMAP.genSearchAction(m, testAccount, message, msymble, mname, mname2)
        require "model"
        assert(IMAP.genSearchAction(Dummy.new,  Model::QA04.cUser(name, Model::DEFAULTPASSWORD),
        "yo", :see, 'SEE', 'UNSEE').class == Array, "Search Action Creation Test")
      end
    end

end

