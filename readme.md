#Using the Ruby based load test is easy!#

**Pre-Requisite**: Install [Couchbase Server 2.2 Enterprise](http://www.couchbase.com/download) on your machine, then.. 

* First, you need a working Ruby environment, follow instructions on http://rvm.io/
* Second, install the libcouchbase c library (www.couchbase.com/communities/c/getting-started)
* Third, install the Ruby couchbase gem and json libraries (gem install json multi_json couchbase)

**On Mac**:
  Make sure you have XCode, Command Line Tools installed/up to date, and
  Make sure you home Homebrew installed and up to date.
  
**On Windows**:
  Follow instructions on the couchbase communities site for the c library that matches your configuration.
  
  
##Load Testing##

```bash
$ ruby load.rb
```

* You can open multiple terminals and do this since each ruby run is single threaded process
* There are only so many operations a single thread/process can generate, so multiple simultaneous runs are needed

Clear out the default bucket between runs

```bash
$ ruby flush.rb
```

* There are a 5 phases of load testing with different mixes of Read/Write. 
* The load.rb file is commented so you can see what is happening
at each phase and the configurable parameters.
  