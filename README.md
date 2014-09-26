logstash-github
===================

This plugin accepts github webhook connections and passes the data into the logstash pipeline.

Usage
=====

Example config:

    input {
        stdin {}
        github {
            port => 8080
        }
    }

    output {
        stdout {
            codec => rubydebug
        }
    }

Example Test Case using Curl:

    curl -H "Content-Type: application/json" -d '{"Something":"xyz","somethingelse":"xyz"}' http://localhost:8080/api/login


Build
=====

Run 'make tarball' to build the project. A tarball will end up in ./build. Extract the file over top of your logstash directory. 
(Hint: or, just copy the ./lib and ./vendor directories to your logstash folder)

Spec Files
==========

If you choose to include some tests, you can create the spec files in the spec directory. I suggest you look at the current logstash/logstash-contrib projects for details.


Todo
====

You'll notice that the bundler will want to be included. :(
