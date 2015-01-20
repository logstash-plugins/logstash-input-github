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

