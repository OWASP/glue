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
To use a built-in tools run Glue in the following format:
```
ruby bin/glue -t Dynamic -T report.json --mapping-file mobsf
```
This will look for a file with the name `mobsf.json` under this [folder](/lib/glue/mappings/).
## Adding a new tool
First, create the mapping file.
After you have a working mapping file, open a PR and add it under `/lib/glue/mappings/`. 
Also add a test to `dynamic_spec`, see mobsf tests for reference.