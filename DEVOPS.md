# DevOps with Glue

The whole reason for building Glue was to try to make it easier to integrate security
tools into continuous delivery.

We don't believe there is *one true way to do DevOps*.  Rather, we believe that we
achieve our best results by continuing to find integration points and leveraging
them.

For that reason, Glue was built to take away the security complexity and provide
very flexible integration strategies.  We aim to provide *options* for integrating
security into build and delivery processs.

The rest of this guide presents _options_ for adding security to your build process.

# Delivery Integration Points

## Developer Desktop Centric

Glue includes a sample git hook that shows how the tools can be run pre-commit to
check for certain conditions and only allow the commit to go through if the tools
don't produce warnings.

See:  /hooks/pre-commit

To install this git hook as is, simply copy that to your .git/hooks directory and
make sure it is executable within your project.  This approach requires docker on
the developers machine.

Note that by altering the packaged git hook, we can easily:
- Choose to only run certain tools
- Make this informational

Of course, there is no reason docker is required.  If developers set up the tools
they need they can install the Glue gem directly and this git hook can be
modified to invoke that directly.

## CI / Build Server Centric

For teams that are using Jenkins or Travis, Glue can be set up to run when
the CI server builds artifacts or runs tests.

We're working on a more detailed example of how to make this work.

This has the advantage of not requiring local developer attention or setup.

## Fit into Current Process

Some organizations have internal systems to track configuration and deployment
across their environment.  In some cases, it can be useful to integrate the
security capabilities into this system because it has all of the information
about the inventory already.

In this kind of case, an exisiting web application can trigger security
analysis and review.

## Rich Custom Application for Inventory and Triage

Groupon built an entire front end for Glue (called [CodeBurner](https://github.com/groupon/codeburner))
that makes it easy for folks to self service the findings and selectively
push them to JIRA or filter them in the future.


## Process Your Images

Glue can run AV and FIM on your virtualized images (docker, iso, etc.)

TODO:  Complete this.
(Build mounters to handle AMI ... etc.?)

## Ad Hoc by Dev or App Security Team

## Reality

Ultimately, there are a variety of places we can plug in security information.
The best solutions usually combine the above options.

Generally, the earlier and more broadly we can think about security, the better.  
That means that having githooks that run for each developer is really useful.  However,
some tools are more effective at that stage.  Some run fast enough to seamlessly
integrate at this point.  Others don't.  Tuning the toolset to apply effectively
is necessary.  This step can only take a few seconds.

As a secondary step, having feedback in CI is essential.  That ensures that a
developer that disables git hooks can't submit that won't be found.  It is also
a spot in the process that can tolerate a longer wait (up to minutes).  So we
might choose to run all of the code analysis tools then.

There may be an integration testing step where it may be adventageous to run
ZAP or other "live" tools against the running test system.

As a background process, it can be helpful to check an inventory of applications
over time as part of a security function.  

Being able to examine artifacts such as VM's, docker images, etc. can be part
of an overall hygeine program.

Having these tools assembled and easy to run might even be useful to
developers and app security folks that want to run them on demand.

# Touch Points

## Feedback

Glue can produce textual warnings, or CSV, JSON or push issues to JIRA.
(In the future github issues?)

The idea is to support a wide variety of reporting outputs to allow
spreadsheet folks to get input or see issues show up right in the dev
workflow in JIRA.

## Build filters

Many tools produce false positives.  Glue has a built in capability to
prevent false positives but we can develop filters to help focus on
things that matter.

Ideally these will be shared with the community.

## More Tools

Glue was designed to make it easy to add additional tools.  Commercial
tools have been integrated and that is intended.  Find us if you have
questions about how to integrate a new tool.
