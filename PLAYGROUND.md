# OWASP Glue Playground

This playground will demo some of Glue's features, to help you understand how it works and what it can do for you.
The playground will use [OWASP Zaproxy](https://github.com/zaproxy/zaproxy) as the alert's source.
To run it, you first need to have a running Zap instance with some alerts in it. 
If you're not sure how this can be done, you can use any other tool that already integrates with Glue.
In the future, we'll consider to create a fake task just for this case, to simplify the demo.
The demo assumes that Zap's running on `http://localhost:1234`, and that the target URL is `http://juice-shop`. Change parameters according to your installation.

## Getting Started

Before playing with Glue, please do the following:
* Access `http://localhost:1234/JSON/core/view/alerts/?zapapiformat=JSON&formMethod=GET&baseurl=http%3A%2F%2Fjuice-shop&start=&count=&riskId=` to make sure Zap's have alerts.
* Run `bundle install` to install all dependencies - or skip this step and use the docker image (`docker run -it soluto/glue:17 sh`)
* Run `ruby bin/glue -h` to make sure Glue is running

## Basic reporting

Run the following command:

```
ruby bin/glue -t zap --zap-host http://localhost --zap-port 1234 --zap-passive-mode http://juice-shop
```

This command will show all the alerts found by Zap in text format. To view it in JSON format (using the `-f flag`):
```
ruby bin/glue -t zap --zap-host http://localhost --zap-port 1234 --zap-passive-mode http://juice-shop -f json
```

## CI Integration

Glue can fail the build by setting the exit code (using the `-z` flag):
```
ruby bin/glue -t zap --zap-host http://localhost --zap-port 1234 --zap-passive-mode http://juice-shop -z
```
Check the exit code (by running `echo $?`), and you'll notice it's 3 - because Glue has finding. This is useful when running Glue in the CI - by setting the exit code, Glue can fail the build on each finding.

You can also customizing how sensitive Glue is. For example, you can decide to fail the build only if high severity issues found, by setting the level (Low - 1, Medium - 2, High - 3) using the `-z 3` flag:
```
ruby bin/glue -t zap --zap-host http://localhost --zap-port 1234 --zap-passive-mode http://juice-shop -z 3
```
And you'll notice the following message by Glue:
```
Worst finding (2) did not meet severity threshold (3)
```
Which indicates that Glue has finding, but not matching the threshold.

### TeamCity Integration
In case you're using TeamCity, Glue can report the findings using TeamCity messaging format, using the `-f teamcity` flag:
```
ruby bin/glue -t zap --zap-host http://localhost --zap-port 1234 --zap-passive-mode http://juice-shop -f teamcity
```
Glue report each finding as a failed or ignored test. By default, all finding that are bellow High, will be reported as ignored test. This can be changed by using the `--teamcity-min-level` flag, and setting it to the requested level. Glue will report each finding on this level and above as failed test:
```
 ruby bin/glue -t zap --zap-host http://localhost --zap-port 1234 --zap-passive-mode http://juice-shop -f teamcity --teamcity-min-level 1
```

## Ignoring Result
Any security tools has false positives, and it's critical to be able to ignore them.
One of Glue's features is the ability to ignore specific findings. To enable this feature, you first need to tell Glue to use a file for filtering the findings (using the `--finding-file-path glue.json`). Replace `glue.json` with the name of the file:
```
ruby bin/glue -t zap --zap-host http://localhost --zap-port 1234 --zap-passive-mode http://juice-shop -z 0 --finding-file-path glue.json
```
Open `glue.json`, and you'll see JSON similar to this file:
```
{
  "ZAPhttp://juice-shop:3000/socket.io/?EIO=3&transport=polling&t=MBIYIdV&sid=kRNKptH5m-LuzwWtAAAAStorable and Cacheable Content": "new",
  "ZAPhttp://juice-shop:3000/socket.io/?EIO=3&transport=polling&t=MBIYIdV&sid=kRNKptH5m-LuzwWtAAAACookie Without SameSite Attributeio": "new",
  "ZAPhttp://juice-shop:3000/socket.io/?EIO=3&transport=polling&t=MBIYIdV&sid=kRNKptH5m-LuzwWtAAAACross-Domain Misconfiguration": "new",
  "ZAPhttp://juice-shop:3000/socket.io/?EIO=3&transport=polling&t=MBIYIdV&sid=kRNKptH5m-LuzwWtAAAACookie Poisoningsid": "new"
}
```
Each line represent one finding, and it's state. The state can be either `new` (Glue will report it), `ignore` (Glue will not report it) or `postpone:%d-%m-%Y` (Glue will ignore this issue until the specific date). This gives you the ability to ignore or postpone the issues found by Glue.

####Docker example
Another example, using Docker:
```
	docker run --rm --name=Glue \
		-v $(PWD):/tmp/triage owasp/glue \
		-t sfl \
		/tmp/triage
```
Because the default output is text, your terminal might display the following:
```
Loading scanner...
Logfile nil?
calling scan
Running scanner
Mounting /tmp/triage with #<Glue::FileSystemMounter:0x000000016215a0>
Mounted /tmp/triage with #<Glue::FileSystemMounter:0x000000016215a0>
Processing target.../tmp/triage
Running tasks in stage: wait
Running tasks in stage: mount
Running tasks in stage: file
Running tasks in stage: code
code - SFL - #<Set:0x00000001698038>
SFL
Running tasks in stage: live
Running tasks in stage: done
Running base report...

	Description: Contains word: password

	Timestamp: 2019-09-10 12:24:19 +0000

	Source: SFL:/tmp/triage/node_modules/foo/bar/passwordrules.js

	Severity: 1

	Fingerprint:  abcdefda571868ff484331cdaa4348f32bd7c59a76c22806a11eeddcdb123456

	Found by:  SFL

	Detail:

	Description: Contains words: private, key

	Timestamp: 2019-09-10 12:24:19 +0000

	Source: SFL:/tmp/triage/node_modules/foo/bar/classPrivateFieldLooseKey.js

	Severity: 1

	Fingerprint:  abcdefb862731c42b16d621598de09516352862c7bf2da5a68bafc4c5d098765

	Found by:  SFL

	Detail:
```
The `Fingerprint` lines can be used to ignore any reported items which you believe are false-positives. Adding a `glue_ignore.json` to the root of your project, place the following:
```
{
  "abcdefda571868ff484331cdaa4348f32bd7c59a76c22806a11eeddcdb123456": "ignore",
  "abcdefb862731c42b16d621598de09516352862c7bf2da5a68bafc4c5d098765": "ignore"
}
```
Finally, modify your Docker script to include `--finding-file-path /tmp/triage/glue_ignore.json`.

```
	docker run --rm --name=Glue \
		-v $(PWD):/tmp/triage owasp/glue \
		-t sfl \
		--finding-file-path /tmp/triage/glue_ignore.json \
		/tmp/triage
```
Now your output should look clean!