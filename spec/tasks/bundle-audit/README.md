## bundler-audit spec tests

### Overview of bundler-audit

[bundler-audit](https://github.com/rubysec/bundler-audit)

Scans a project's vulnerable versions of gems in the `Gemfile.lock` file and checks for gem sources without TLS.

The names/versions are compared against the [ruby-advisory-db ](https://github.com/rubysec/ruby-advisory-db).

To install bundler-audit:
```
gem install bundler-audit
```

The simplest way to run it from the command line is to `cd` to the folder with the `Gemfile.lock` file and call:
```
bundle-audit check
```

In Glue, `bundler-audit` is called with the following argument:
```
bundle-audit check
```

Some other command line options when running bundler-audit locally:
* `--update` - Updates the ruby-advisory-db;
* `--ignore [ADVISORY-ID]` - Ignores specific advisories.

See [bundler-audit documentation](https://www.rubydoc.info/gems/bundler-audit/frames) for more info.

### The spec tests

The specs do not call the bundler-audit tool because this would be too slow (~1 sec per spec test).
Instead the specs rely on stubbing Glue's `runsystem` method (which calls CLI commands).

In the specs, the return value of `runsystem` is always a canned response.
Either it will be a generic, minimal response, or it will be a snapshot of an actual bundler-audit report.

The actual reports were generated via the script `generate_reports.sh`.
The targets of the spec tests were set up in a minimal way to produce non-trivial output.
This required a `Gemfile.lock` file per target.
