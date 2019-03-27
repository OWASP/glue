# Dynamic Task
The dynamic task allows you to integrate new security tools into Glue without writing new code.
This is done by creating a mapping files that instruct Glue how to create findings from the tool report.
Currently, there is only support for JSON reports, but this can be extended in the future.

## Integrating a New Tool
### Create the mapping file
The mapping file should map between the issues in the report to the matching fields in Glue's finding.
THis is a JSON file, and you can find the schema [here](/lib/glue/mappings/schema.json).
Here is the mapping file for [MobSF](https://github.com/MobSF/Mobile-Security-Framework-MobSF):
```JSON
{
  "task_name": "MobSF",
  "app_name": "name",
  "mappings": [
    {
      "key": "manifest",
      "properties": {
        "description": "desc",
        "detail": "title",
        "source": "title",
        "severity": "stat",
        "fingerprint": "title"
      }
    }
  ]
}
```
You'll need to create a similar file in order to process the report of your tool.
Checkout the schema, it contains the documentation for all the fields.
### Using the new schema
After creating the mapping file, run Glue in the following format:
```
ruby bin/glue -t Dynamic -T report.json --mapping-file mapping.json
```
Replace `report.json` and `mapping.json` with the paths to the relevant files.

## Built-In Tools
The dynamic task support built-in mappings, that are shipped with Glue. 
Those mapping files aims to help others to use the mapping your created.

### MobSF

To parse MobSF report, use the following format:
```
ruby bin/glue -t Dynamic -T report.json --mapping-file mobsf
```
where `report.json` is your report

### Zaproxy
To parse Zaproxy report, you first need to generate it by using the API:
```
curl --fail $PROXY_URL/OTHER/core/other/jsonreport/?formMethod=GET --output report.json
```
Than, use [jq](https://stedolan.github.io/jq/) to flatten the report so Glue can parse it:
```
jq '{ "@name" : .site[0]."@name",
  "alerts": 
  [.site[] | .alerts[] as $in 
  | $in.instances[] as $h 
  | $in
  | $h * $in
  | {
      "description": $in.desc, 
      "source": "URI: \($h.uri) Method: \($h.method)",
      "detail": "\($in.name) \n Evidence: \($h.evidence) \n Solution: \($in.solution) \n Other info: \($in.otherinfo) \n Reference: \($in.reference)",
      "severity": $in.riskdesc | split(" ") | .[0],
      "fingerprint": "\($in.pluginid)_\($in.name)_\($h.uri)_\($h.method)" 
    }
  ]
}' report.json > output.json
```
Now use Glue to process the report:
```
ruby bin/glue -t Dynamic -T report.json --mapping-file zaproxy
```
You can modify the jq pattern to modify the fields in Glue's results. For example, you might want to remove `otherinfo`, or use something else for the fingerprint.
## Adding a new tool
First, create the mapping file.
After you have a working mapping file, open a PR and add it under `/lib/glue/mappings/`. 
Also add a test to `dynamic_spec`, see mobsf tests for reference.
