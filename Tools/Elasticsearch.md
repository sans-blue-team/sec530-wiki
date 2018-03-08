Elasticsearch
========
Abstract
---------
Elasticsearch is a distributed, RESTful search and analytics engine, and makes up the heart of the SIEM used in SEC455. It is the main storage and search component of the Elastic Stack.

Where to Acquire
---------
Elasticsearch can be downloaded from https://www.elastic.co/products/elasticsearch. It is open source but also has a commercial support offering.

Documentation
---------
The documentation for the latest version of Elasticsearch can be found at https://www.elastic.co/guide/en/elasticsearch/reference/master/index.html.

Troubleshooting
---------
If you have a node that either won't start up, or is failing after a period of time, the reason should be present in the log files. Depending on the point at which it failed, there are a couple options for checking the reason.

1. The systemd journal.
2. The cluster logs in /var/log/elasticsearch/
3. The trace logs, which must be enabled.

To tail the elasticsearch service logs written to the systemd journal, use the command below. It can be helpful to leave this command running in a terminal window while trying to diagnose the problem.

```bash
$ sudo journalctl -u elasticsearch.service -f
```

To view the entire systemd journal for all services, which may help in case the issue is being caused with another service, this command can be used.

```bash
$ sudo journalctl -xe
```

Often times, if the node is not able to start, the reasons will not be present in the systemd journal. In this case you should check the main elasticsearch log files, written by default to /var/log/elasticsearch/[clustername].log. This folder contains multiple logs files: the normal cluster log (sec455.log), the deprecation log (sec455_deprecation.log), and the slowlog (sec455_index_search_slowlog.log). FOr troublshooting, you are interested in the log that matches the cluster name, in the case of the VM, sec455.log.

```bash
root@sec455:/# ls /var/log/elasticsearch/
sec455-2018-01-15-1.log.gz  sec455-2018-01-16-1.log.gz  sec455_deprecation.log  sec455_index_indexing_slowlog.log  sec455_index_search_slowlog.log  sec455.log
```

In the case of the class VM, the following command will show the elasticsearch log file, as well as use tail to continuously monitor it. Be aware that by default, **you will need to use root access** to read the elasticsearch log files. It can be helpful to leave this command running in a terminal window while issuing the "sudo service elasticsearch restart" command to find what errors are generated when the node is started. Be aware that logs can be very verbose so you may want to filter for lines that contain WARN or FATAL and ignore INFO line.

```bash
$ sudo cat /var/log/elasticsearch/sec455.log
$ sudo tail -f /var/log/elasticsearch/sec455.log
```

Logs from previous days are gzipped to save space. These can still be viewed without uncompressing them by using the "zcat" command such as in the example below. It may be helpful to filter out the lines that contain INFO using the output pipped to a grep command eliminating lines that contain the "INFO" tag, however be aware that since the log entries can span multiple lines, this may not perfectly filter it out.

```bash
$ sudo zcat /var/log/elasticsearch/sec455-2018-01-15-1.log.gz
$ sudo zcat /var/log/elasticsearch/sec455-2018-01-15-1.log.gz | grep -v INFO
```

If you need to go even deeper on debugging, you can turn up log4j2 settings to "trace" level by inserting the following line into the elasticsearch.yml file and restarting the elasticsearch process. Be sure to turn this back off after it is no longer needed, since it will cause log files to be extremely verbose.

```bash
logger.org.elasticsearch.transport: trace
```

Shard Allocation Investigation
---------
At some point in time, you may find yourself wondering why shards are not being allocated in the way you expect. To answer this question, Elasticsearch provides the cluster level Explain API - https://www.elastic.co/guide/en/elasticsearch/reference/current/cluster-allocation-explain.html. Issuing the following command via the Dev Tools interface or Cerebro will provide an explanation why allocation is in the state it is in.

```bash
GET /_cluster/allocation/explain
```

elasticsearch.yml Setup Options
---------
For detailed reference on the options below in the /etc/elasticsearch/elasticsearch.yml file, consult the Elasticsearch Modules section of the help documents: https://www.elastic.co/guide/en/elasticsearch/reference/current/modules.html

Once any options in this section are changed, the elasticsearch serivce will need to be restarted for the changes to take effect

```bash
sudo service elasticsearch restart
```

Snapshot and Restore
---------
Assuming that the shared filesystem is mounted to /mount/backups/my_backup, the following setting should be added to elasticsearch.yml file:

```bash
path.repo: ["/mount/backups", "/mount/longterm_backups"]
```

The path.repo setting supports Microsoft Windows UNC paths as long as at least server name and share are specified as a prefix and back slashes are properly escaped:

```bash
path.repo: ["\\\\MY_SERVER\\Snapshots"]
```

URL Repositories are read-only sources for restoring data. They support the following protocols: "http", "https", "ftp", "file" and "jar". URL repositories with http:, https:, and ftp: URLs have to be whitelisted by specifying allowed URLs in the **repositories.url.allowed_urls** setting. This setting supports wildcards in the place of host, path, query, and fragment. For example:

```bash
repositories.url.allowed_urls: ["http://www.example.org/root/*", "https://*.mydomain.com/*?*#*"]
```

Networking
---------
By default, Elasticsearch will only listen on the local loopback interface (127.0.0.1), when you go to form a cluster in production, you will need to modify these settings so nodes can talk to each other over the network. This involves 2 steps, setting the **network.host** variable to tell Elasticsearch to listen on other network interfaces, and setting the discovery.zen.ping.unicast.hosts variable to point to the other nodes in the cluster.

**network.host:**
The following special values may be set for **network.host** in the elasticsearch.yml file, and multiple can be used at once separated by a comma:

```bash
_local_ - Any loopback addresses on the system, for example 127.0.0.1 (this is the default).

_site_ - Any site-local addresses on the system, for example 192.168.0.1.

_global_ - Any globally-scoped addresses on the system, for example 8.8.8.8. 

_[networkInterface]_ - Addresses of a network interface, for example _en0_. 
```

Example:
```bash
network.host: _site_,_local_
```

**discovery.zen.ping.unicast.hosts:**
In order to join a cluster, a node needs to know the hostname or IP address of at least some of the other nodes in the cluster. This setting provides the initial list of other nodes that this node will try to contact. Accepts IP addresses or hostnames. If a hostname lookup resolves to multiple IP addresses then each IP address will be used for discovery.

Example:
```bash
discovery.zen.ping.unicast.hosts: ["10.0.0.2", "10.0.0.3", "10.0.0.4"]
```

Remember, it is **very important** to set the minimum master nodes that must be visibile to avoid split brain. The formula for the correct amount is (master-eligible nodes/2) + 1. FOr a 3 node cluster, use 2, for a 10 node cluster, use 6, etc.

Example:
```bash
discovery.zen.minimum_master_nodes: 2
```

For discovery using clusters in ECS, Azure, and Google Computer Engine, refer to the following URL: https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-discovery.html 

Node Type Setup
---------
In order to designate whether your node can act as a master, data, ingest, or coordinating node, the options below must be specified in the **elasticsearch.yml** file. Note that if X-Pack is installed, there is an extra node type available for machine learning and the settings from the X-Pack section below should be used.

If X-Pack is **not** installed, use this configuration to create a dedicated **master-eligible** node:

```bash
node.master: true 
node.data: false 
node.ingest: false 
search.remote.connect: false
```

For a dedicated **data** node **without** X-Pack installed:
```bash
node.master: false 
node.data: true 
node.ingest: false 
search.remote.connect: false
```

For a **coordinating** node **without** X-Pack installed: 

```bash
node.master: false 
node.data: false 
node.ingest: false 
search.remote.connect: false
```

If X-Pack **is** installed with machine learning, use this configuration to create a dedicated **master-eligible** node:

```bash
node.master: true 
node.data: false 
node.ingest: false 
node.ml: false 
xpack.ml.enabled: true
```

For a dedicated **data** node **with** X-Pack installed: 

```bash
node.master: false 
node.data: true 
node.ingest: false 
node.ml: false 
```

For a **coordinating** node **with** X-Pack installed: 

```bash
node.master: false 
node.data: false 
node.ingest: false 
search.remote.connect: false 
node.ml: false
```

Curator Examples
---------
To install Curator, run the below command. Note that if pip is not installed, you may need to install that first with "sudo apt install python-pip" or your distributions package manager equivalent.

```bash
$ pip install elasticsearch-curator
```

Reference for the Curator configuration file (curator.yml) can be found at the url below, this configuration must be set up before Curator can be successfully run. https://www.elastic.co/guide/en/elasticsearch/client/curator/current/configfile.html 

Multiple examples for curator scripts can be found on the curator site at the following url: https://www.elastic.co/guide/en/elasticsearch/client/curator/current/examples.html. 

Be aware that these scripts come disabled due to the "disable_action: True" line. Remove this line when testing (even dry runs) or no results will be shown. 

It is **highly advised** that you try these out using the "--dry-run:" parameter before running them.

Benchmarking Elasticsearch
---------
Elastic has developed a benchmarking suite called "Rally" for testing your hardware for Elasticsearch performance. https://github.com/elastic/rally Note it is **NOT** designed to test a pre-exisiting, cluster. It CAN be done that way, but the preferred method is to issue the command to benchmark, and let the Rally package set up its own benchmarking cluster for testing. This will yield the most detailed and accurate results. This means you should run this suite on your hardware **before** you install Elasticsearch on it for production.

To install Rally, note you may need to install pip for Python 3 first with "sudo apt install python3-pip" or your distributions package manager equivalent.

```bash
$ pip3 install esrally
```

To run a "race", you must first configure esrally, then run the esrally command with a argument for the version of elasticsearch you would like to test. This will fully install the elasticsearch packages and everything involved.

```bash
$ esrally configure
$ esrally --distribution-version=6.0.0
```

Note that Rally has different benchmarks for different use cases called "tracks". Of the defaults, the "http_logs" track is likely the most applicable for a SIEM use case. To run this track, use the command line argument below.

```bash
$ esrally --distribution-version=6.0.0 --track=http_logs
```

For detailed instructions on customizing the test, consult the esrally documentation at https://esrally.readthedocs.io/en/latest/index.html.

Text Analysis and Tokenization
---------
If you would like to experiment with different types of text analysis, the Elasticsearch Analyze API can be used to see how your input text will be separated into tokens. For an example, paste the entire section below into the Kibana Dev Tools window and analyze the tokens that are output as each different request is submitted. Note that an analyzer is defined as a pre-defined set of character filters, token filters, and a tokenizer. The tokenizer is what breaks up the strings into tokens, and the token filters then modify the broken up tokens further (for example reversing them in some cases below). 

```bash
GET _analyze
{
  "analyzer" : "standard",
  "text" : "MiXed-CaSE WritinG with SPeciaL-!@@=RANDOM}{-ChARACTERS"
}

GET _analyze
{
  "tokenizer" : "standard",
  "text" : "MiXed-CaSE WritinG with SPeciaL-!@@=RANDOM}{-ChARACTERS"
}

GET _analyze
{
  "tokenizer" : "standard",
  "text" : "http://www.google.com/search/file.jpg, https://wiki.sans-training.local, instructor@sans.org"
}

GET _analyze
{
  "tokenizer" : "uax_url_email",
  "explain" : "true",
  "text" : "http://www.google.com/search/pic.jpg, https://wiki.sans-training.local, instructor@sans.org"
}

GET _analyze
{
  "tokenizer" : "standard",
  "filter" : ["reverse"],
  "text" : "http://www.google.com/search/pic.jpg, https://wiki.sans-training.local, instructor@sans.org"
}

GET _analyze
{
  "tokenizer" : "uax_url_email",
  "filter" : ["reverse"],
  "text" : "http://www.google.com/search/pic.jpg, https://wiki.sans-training.local, instructor@sans.org"
}
```

To see a list of tokenizers and token filter options see the following URLs:

Anatomy of an Analyzer: https://www.elastic.co/guide/en/elasticsearch/reference/current/analyzer-anatomy.html 
Tokenizers: https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-tokenizers.html
Token Filters: https://www.elastic.co/guide/en/elasticsearch/reference/current/analysis-tokenfilters.html