#!/bin/env ruby
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
# Net/POP modification
# 
require 'net/pop'
require 'base64'

begin
  require 'openssl'
rescue LoadError
end

class Net::POP3Command
  attr :socket, true
  
  def xoip(mstring)
    check_response(critical { get_response("XOIP #{mstring}")})
  end
  
  def authPlain(pUser, pCredential, pPassword)
    dataString = "#{pUser}#{0.chr}#{pCredential}#{0.chr}#{pPassword}" 
    check_response_auth(critical {
      get_response('AUTH PLAIN %s', Base64.encode64(dataString).gsub(/\n/,"")) 
    }) 
  end
  
  def doTLS
    getok "STLS"
  end
  
end

class Net::POP3
  
  alias_method :old_initialize, :initialize
  attr :tls, true
  
  def initialize(addr, port = nil, isapop = false)
    self.tls = false
    @sock = nil
    port = self.class.default_port if !port
    old_initialize addr, port, isapop
  end 
   
  
  def do_start( account, password )
    #@socket = self.class.socket_type.old_open(@address, @port,
    #                                          @open_timeout, @read_timeout, @debug_output)
    @sock = timeout(@open_timeout) { TCPSocket.open(@address, @port) }
    @socket = Net::InternetMessageIO.new(@sock)
    @socket.read_timeout = @read_timeout
    @socket.debug_output = @debug_output
    
    on_connect
    @command = if (tls && @socket)
      raise 'openssl is not installed' unless defined?(OpenSSL)
      mCommand = Net::POP3Command.new(@socket)
      res = mCommand.doTLS 
      ssl = OpenSSL::SSL::SSLSocket.new(@sock) 
      ssl.sync_close = true
      ssl.connect
      @socket = Net::InternetMessageIO.new(ssl)
      @socket.read_timeout = @read_timeout
      @socket.debug_output = @debug_output
      puts "TLS RESPONSE #{res}" if $DEBUG 
      mCommand.socket = @socket
      mCommand
    else 
      Net::POP3Command.new(@socket)
    end 
    if apop?
      @command.apop account, password
    else
      @command.auth account, password
    end 
    @started = true 
  ensure
    unless @started # close connection if failure, don't issue QUIT (do_finish)
      @sock.close if @sock and not @sock.closed?
      @socket = nil
      @command = nil
    end
  end 
end

class Net::POP3::AuthPlain < Net::APOP
  alias :old_do_start :do_start
  alias :old_start :start
  
  def plain?
    true
  end
  
  def started?
    @started
  end
  
  def start( account, password, accounti = nil ) # :yield: pop
    raise IOError, 'POP session already started' if @started
    
    if block_given?
      begin
        do_start account, password, accounti
        return yield(self)
      ensure
        do_finish
      end
    else
      do_start account, password, accounti
      return self
    end
  end
  
  
  def do_start( account, password, accounti = nil )
    #old old trap
    
    if(RUBY_VERSION > "1.8.2" && RUBY_VERSION < "1.9")
        @socket = self.class.socket_type.old_open(@address, @port,
                                              @open_timeout, @read_timeout, @debug_output)
    else
        socket = timeout(@open_timeout) { TCPSocket.open(@address, @port) }
        @socket = self.class.socket_type.new(socket)
        @socket.read_timeout = @read_timeout
        @socket.debug_output = @debug_output
    end
    on_connect
    @command = Net::POP3Command.new(@socket) 
    @command.authPlain accounti, account, password 
    @started = true 
    ensure
      unless @started # close connection if failure, don't issue QUIT (do_finish)
        @sock.close if @sock and not @sock.closed?
        @socket = nil
        @command = nil
      end
  end
end

class Net::POP3
  
  
end