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

Configuration
=============

* ip - The IP you want to listen on (Default: 0.0.0.0)
* port - The port you want to listen on
* secret_token - The shared secret set for github webhook
* drop_invalid - Drop events that don't match the secret_token

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
