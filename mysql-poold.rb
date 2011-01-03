#!/usr/bin/env ruby
require 'rubygems'
require 'mysql-ext'
require 'drb/drb'
require 'fdpass'
require 'logger'

LOG = Logger.new($stderr)

class MysqlPoolServer
  def initialize(config = {})
    @mutex = Mutex.new
    @pool = []
    @map = {}

    @host   = config.fetch(:host, '127.0.0.1')
    @user   = config.fetch(:user, 'root')
    @passwd = config.fetch(:password, '')
    @db     = config.fetch(:database)
    @port   = config.fetch(:port, 3306)

    size = config.fetch(:size, 5)
    size.times { pool_new_connection }
    LOG.info("pool size is #{@pool.size}")
  end

  def checkout(pid)
   LOG.info("chekout to #{pid}")

   @mutex.synchronize {
      pool_new_connection if @pool.empty?
      conn = @pool.shift
      fdpass = FDPass.client("/tmp/mysql-pool.#{pid}.sock")
      fdpass.send(conn.to_sock.fileno)
      @map[pid] = conn
    }

    LOG.info("pool size is #{@pool.size}")
  end

  def checkin(pid)
   LOG.info("chekin from #{pid}")

    @mutex.synchronize {
      conn = @map.delete(pid)
      @pool.push(conn)
    }

    LOG.info("pool size is #{@pool.size}")
  end

  def close
    (@pool + @map.values).each do |conn|
      conn.close
      LOG.info("close conn: #{conn}")
    end
  end

  private
  def pool_new_connection
    conn = Mysql.new(@host, @user, @passwd, @db, @port)
    LOG.info("new conn: #{conn}")
    @pool.push(conn)
  end
end

poold = MysqlPoolServer.new(:database => 'pool_test')
DRb.start_service('drbunix:/tmp/mysql-pool.sock', poold)
trap(:INT) { poold.close; exit }
LOG.info('start')
sleep
