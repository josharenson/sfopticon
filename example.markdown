=== A Common Workflow

The workflow we use, and what we expect to be a common workflow out in the wild, is a 
production environment with full sandboxes for feature development and hotfixes where the hotfix sandbox is kept in sync with production, and the sandboxes are updated with any interim deploys to production for hotfix or separate feature release.

Let's walk through using SfOpticon to manage this scenario.

First setup your environments. You must create your production environment first. You can specify --username and --password on the command line, or leave them out and allow the script to query you. Additionally, you can add --securitytoken.

	bin/environment.rb create --name Prod --host login.salesforce.com --production
	bin/environment.rb create --name Hotfix --host test.salesforce.com
	bin/environment.rb create --name Sandbox1 --host test.salesforce.com

<graph2.png>
Resulting environment graph

== Change Monitoring

You'll want to setup the changeset scanner to execute every 20 minutes or so. This is 
the piece that watches your Salesforce orgs, detects changes, and adds those changes 
to the underlying VCS.

Add a line to cron for each environment.

	*/20 * * * bin/scanner.rb changeset --org Prod
	*/20 * * * bin/scanner.rb changeset --org Hotfix
	*/20 * * * bin/scanner.rb changeset --org Sandbox1

Note that this is the reverse of the common solution. Rather than committing our changes to the VCS and then deploying them to the org, simply go about your development as you normally do and allow the tools to manage the VCS integration. This has the benefit of allowing us to track declarative and configuration changes.

Now, you've been running SfOpticon for the past week as your developers have been working on a new feature. The production org shouldn't have had any changes since all changes are happening in a sandbox.

== Deployment

Now imagine that a SEV1 issue has just come in and you need to get this deployed to production right away. Hack away on the hotfix environment until you're ready for deploy.

Execute:

	bin/integrate.rb merge --source Hotfix --destination Production

This command will create a temporary integration branch from the Production branch, merge in the changes to Hotfix, generate destructive and productive manifests from the branch diffs, and deploy your changes to production.

Pretty cool, yeah?

But wait. Now Sandbox1 is out of sync with production. What's more, maybe the SEV1 you just pushed has overlapping code with your feature on the sandbox.

== Rebasing

It's time to rebase!

Rebasing will take any changes in the production environment and merge them into the sub-environment using the VCS merging tools. 

	bin/integrate.rb rebase --org Sandbox1

Voila! Not only do you have the changes in production, but if there was code overlap it's properly merged!

Alternatively you could've executed the merge using the hotfix and sanbox names for the merge arguments. This is useful to move code around for integration testing, UAT, etc.

	bin/integrate.rb merge --source Hotfix --destination Sandbox1

If there are merge conflicts you'll be notified and the script will exit. 

== Cherry Picking

Say you would like to choose which changes on Sandbox1 you'd like to deploy to Production. We understand. We want that feature too, and it's on the roadmap. However it doesn't exist today. Today you'll need to actually undo those changes in the source environment and allow the scanner to apply the changeset to the VCS prior to deployment.
