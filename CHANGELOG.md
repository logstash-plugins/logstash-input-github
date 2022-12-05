## 3.0.11
  - Change `secret_token` config type to `password` for better protection from leaks in debug logs [#23](https://github.com/logstash-plugins/logstash-input-github/pull/23)

## 3.0.10
  - Changed the transitive dependency `http_parser.rb` (ftw) version to `~-> 0.6.0` as newer versions are published without the java support.
  - Fixed crashing when the request body payload is not a JSON object.  [#24](https://github.com/logstash-plugins/logstash-input-github/pull/24)  

## 3.0.9
  - Bump ftw dependency to 0.0.49, for compatibility with Logstash 7.x

## 3.0.8
  - Require x-hub-signature header if secret_token defined

## 3.0.7
  - Docs: Set the default_codec doc attribute.

## 3.0.6
  - Improve malformed-input handling by using updated FTW
  - Improve webserver crash recovery
  - Properly support plugin stopping & reloading

## 3.0.5
  - Update gemspec summary

## 3.0.4
  - Fix some documentation issues

## 3.0.1
  - Relax constraint on logstash-core-plugin-api to >= 1.60 <= 2.99

## 3.0.0
 - breaking: Updated plugin to use new Java Event APIs

## 2.0.5
 - Depend on logstash-core-plugin-api instead of logstash-core, removing the need to mass update plugins on major releases of logstash

## 2.0.4
 - New dependency requirements for logstash-core for the 5.0 release

## 2.0.0
 - Plugins were updated to follow the new shutdown semantic, this mainly allows Logstash to instruct input plugins to terminate gracefully, 
   instead of using Thread.raise on the plugins' threads. Ref: https://github.com/elastic/logstash/pull/3895
 - Dependency on logstash-core update to 2.0
