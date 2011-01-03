require 'rubygems'
require 'mysql-ext'
require 'drb/drb'
require 'fdpass'

class MysqlPool
  def initialize
    @poold = DRbObject.new_with_uri('drbunix:/tmp/mysql-pool.sock')
    @mutex = Mutex.new
  end

  def checkout
    @mutex.synchronize {
      fdpass = FDPass.server("/tmp/mysql-pool.#{$$}.sock")
      @poold.checkout($$)
      fd = fdpass.recv
      sock = BasicSocket.for_fd(fd)
      Mysql.from_sock(sock)
    }
  end

  def checkin
    @mutex.synchronize {
      @poold.checkin($$)
    }
  end
end
