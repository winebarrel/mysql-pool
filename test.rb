#!/usr/bin/env ruby
require 'mysql-pool'
require 'tracer'

pool = MysqlPool.new

begin
  my = pool.checkout

  loop do
    my.query('show tables') do |rs|
      rs.each do |row|
        puts "#{$$}: #{row.inspect}"
      end
    end

    sleep 1
  end
ensure
  pool.checkin
end