require 'rubygems'  # poor people still on 1.8
gem 'redis', '>= 3.0.0'
require 'redis'

$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'bacon'
Bacon.summary_at_exit
if $0 =~ /\brspec$/
  raise "\n===\nThese tests are in bacon, not rspec.  Try: bacon #{ARGV * ' '}\n===\n"
end

REDIS_CLASS_NAMES = [:Counter, :HashKey, :List, :Lock, :Set, :SortedSet, :Value]

UNIONSTORE_KEY = 'test:unionstore'
INTERSTORE_KEY = 'test:interstore'
DIFFSTORE_KEY  = 'test:diffstore'

# Start our own redis-server to avoid corrupting any others
REDIS_BIN  = 'redis-server'
REDIS_PORT = ENV['REDIS_PORT'] || 9212
REDIS_HOST = ENV['REDIS_HOST'] || 'localhost'
REDIS_PID  = File.expand_path 'redis.pid', File.dirname(__FILE__)
REDIS_DUMP = File.expand_path 'redis.rdb', File.dirname(__FILE__)

describe 'redis-server' do
  it "starting redis-server on #{REDIS_HOST}:#{REDIS_PORT}" do
    fork_pid = fork do
      system "(echo port #{REDIS_PORT}; echo logfile /dev/null; echo daemonize yes; echo pidfile #{REDIS_PID}; echo dbfilename #{REDIS_DUMP}) | #{REDIS_BIN} -"
    end
    fork_pid.should > 0
  end
end

at_exit do
  pid = File.read(REDIS_PID).to_i
  puts "=> Killing #{REDIS_BIN} with pid #{pid}"
  Process.kill "TERM", pid
  Process.kill "KILL", pid
  File.unlink REDIS_PID
  File.unlink REDIS_DUMP if File.exists? REDIS_DUMP
end

# Grab a global handle
REDIS_HANDLE = Redis.new(:host => REDIS_HOST, :port => REDIS_PORT)
$redis = REDIS_HANDLE

SORT_ORDER = {:order => 'desc alpha'}
SORT_LIMIT = {:limit => [2, 2]}
SORT_BY    = {:by => 'm_*'}
SORT_GET   = {:get => 'spec/*/sorted'}.merge!(SORT_LIMIT)
SORT_STORE = {:store => "spec/aftersort"}.merge!(SORT_GET)
