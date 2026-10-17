# GitHub workflows

Versioned CI definitions for validating Starfall.

## Start here

Read each workflow’s triggers and permissions before changing it. A workflow definition is not evidence of a successful run.

The main simulator workflow also runs device-updater decision tests without network/device access. The local updater waits for that exact-source workflow to succeed before installing; it does not use cloud signing or expose the iPhone to a hosted runner.
