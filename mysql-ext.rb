gem 'ruby-mysql'
require 'mysql'

class Mysql
  class Protocol
    def self.from_sock(sock)
      protocol = self.allocate
      protocol.set_sock(sock)
      return protocol
    end

    def set_sock(sock)
      @sock = sock
      @gc_stmt_queue = []
      @charset = Charset.by_number(254)
      set_state(:READY)
      return self
    end
  end

  def to_sock
    self.protocol.instance_variable_get(:@sock)
  end

  def self.from_sock(sock)
    protocol = Protocol.from_sock(sock)
    my = self.allocate
    my.set_protocol(protocol)
  end

  def set_protocol(protocol)
    @protocol = protocol
    @charset ||= @protocol.charset
    @host_info = "mysql-pool"
    return self
  end
end
