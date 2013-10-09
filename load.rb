# Simple Load Generator
# Does 1.6 Million Operations
# Single Threaded Ruby Gem Based
# Can be run in multiple terminals if you set the USE_ATOMIC_COUNTER_FOR_CREATE to true
# => doing so will increase number of operations by 300K, if true, make sure you run all instances with true

require 'rubygems'
require 'couchbase'

# If you want to run this in multiple terminals, change this to true
USE_ATOMIC_COUNTER_FOR_CREATE = true

# if true, run flush.rb before testing to empty db
WILL_RUN_MULTIPLE_INSTANCES = true 

# To see a demo of how this can happen, size the default bucket to 100MB and write like crazy, 
# it can happen faster if you increase the random_text size to something really big
# Out of Memory - Temporary Fail Error Count
$E_OOM = 0

# Size of Random Text Hash Key (JSON KEY), multiple of 26 letters plus space (27 bytes)
RANDOM_TEXT_MULTIPLE = 100 # 100 == 2700 bytes, 2.7 K

# Create a new connection to default bucket and flush out all data
C = Couchbase.new

unless WILL_RUN_MULTIPLE_INSTANCES
  C.flush 
  puts "Flushing and sleeping for 2 seconds..."
  sleep(2)
end

# If we are going to use an atomic counter, create it
if USE_ATOMIC_COUNTER_FOR_CREATE
  begin
    C.add("itemcount", 0)    
  rescue Couchbase::Error::KeyExists
    # Already created in another instance
  end
end

# quick function to return a repeated string
def repeat(input, n)
  ([input] * n).join ' '
end

# quick function to output errors
def show_oom_error
  $E_OOM += 1
  puts "ERROR - OOM, Bucket RAM Quota Too Small, Ejection from RAM too slow for write velocity  #{$E_OOM}"
end

# Create random data string field to increase document sizes, is a multiple of 27, uses RANDOM_TEXT_MULTIPLE
random_text = repeat("abcdefghijklmnopqrstuvwxyz", RANDOM_TEXT_MULTIPLE)
data = { random_text: random_text }




# Phase 1
# Create 100K items, add time stamp and item # as json data (Hash)
# Read 0%, Write 100%
#
puts "Phase 1 --- Read   0%, Write 100% --- Create 100,000 items..."
100000.times do |i|
  data[:item] = i
  data[:created_at] = Time.now.utc.to_i

  begin
    if USE_ATOMIC_COUNTER_FOR_CREATE
      id = C.incr("itemcount")
      C.add("item::#{id}", data)      
    else
      C.add("item::#{i}", data)
    end
  rescue Couchbase::Error::TemporaryFail
    show_oom_error
  end

end




# Phase 2
# Create 100K more items, add time stamp and item #, retrieve and replace 100K items
# Read 33%, Write 66%
# 

current_count = C.get("itemcount") if USE_ATOMIC_COUNTER_FOR_CREATE
current_count = 100000 unless USE_ATOMIC_COUNTER_FOR_CREATE

puts "Phase 2 --- Read  33%, Write  66% --- Create 100,000 items, Get & Replace 100,000 items..."
100000.times do |i|

  # get a random item and replace it, add an updated_at json key (Hash Key)
  key = "item::#{rand(current_count) + 1}"
  data = C.get(key)
  data[:updated_at] = Time.now.utc.to_i
  begin
    C.replace(key, data)
  rescue Couchbase::Error::TemporaryFail
    show_oom_error
  end
  
  data = { random_text: random_text }
  data[:item] = i
  data[:created_at] = Time.now.utc.to_i
  begin
    if USE_ATOMIC_COUNTER_FOR_CREATE
      id = C.incr("itemcount")
      C.add("item::#{id}", data)      
    else
      C.add("item::#{100000 + i}", data)
    end
  rescue Couchbase::Error::TemporaryFail
    show_oom_error
  end
end





# Phase 3
# Retrieve 100K items, Create 100K more items, add time stamp and item #, retrieve and replace 100K items
# Read 33%, Write 66%
#

current_count = C.get("itemcount") if USE_ATOMIC_COUNTER_FOR_CREATE
current_count = 200000 unless USE_ATOMIC_COUNTER_FOR_CREATE

puts "Phase 3 --- Read  33%, Write  66% --- Get 100,000 items, Get & Replace 100,000 items, Create 100,000 items..."
100000.times do |i|

  key = "item::#{rand(current_count) + 1}"
  data = C.get(key)

  key = "item::#{rand(current_count) + 1}"
  data = C.get(key)
  data[:updated_at] = Time.now.utc.to_i
  begin
    C.replace(key, data)
  rescue Couchbase::Error::TemporaryFail
    show_oom_error
  end
  
  data = { random_text: random_text }
  data[:item] = i
  data[:created_at] = Time.now.utc.to_i
  begin
    if USE_ATOMIC_COUNTER_FOR_CREATE
      id = C.incr("itemcount")
      C.add("item::#{id}", data)      
    else
      C.add("item::#{200000 + i}", data)
    end    
  rescue Couchbase::Error::TemporaryFail
    show_oom_error
  end
end




# Phase 4
# Retrieve 300K items, retrieve and replace 200K items
# Read 60%, Write 40%
#

current_count = C.get("itemcount") if USE_ATOMIC_COUNTER_FOR_CREATE
current_count = 300000 unless USE_ATOMIC_COUNTER_FOR_CREATE

puts "Phase 4 --- Read  60%, Write  40% --- Get 300,000 items, Get & Replace 200,000 items..."
100000.times do |i|
  key = "item::#{rand(current_count) + 1}"
  data = C.get(key)

  key = "item::#{rand(current_count) + 1}"
  data = C.get(key)
  data[:updated_at] = Time.now.utc.to_i
  begin
    C.replace(key, data)
  rescue Couchbase::Error::TemporaryFail
    show_oom_error
  end
  
  key = "item::#{rand(current_count) + 1}"
  data = C.get(key)

  key = "item::#{rand(current_count) + 1}"
  data = C.get(key)
  
  key = "item::#{rand(current_count) + 1}"
  data = C.get(key)
  data[:updated_at] = Time.now.utc.to_i
  begin
    C.replace(key, data)
  rescue Couchbase::Error::TemporaryFail
    show_oom_error
  end
end




# Phase 5
# Retrieve 500K items
# Read 100%, Write 0%
#

current_count = C.get("itemcount") if USE_ATOMIC_COUNTER_FOR_CREATE
current_count = 300000 unless USE_ATOMIC_COUNTER_FOR_CREATE

puts "Phase 5 --- Read 100%, Write   0% --- Get 500,000 items..."
500000.times do |i|
  key = "item::#{rand(current_count) + 1}"
  data = C.get(key)
end

