# GitHub workflows

Versioned CI definitions for validating Starfall.

## Start here

Read each workflow’s triggers and permissions before changing it. A workflow definition is not evidence of a successful run.

The main simulator workflow also runs device-updater decision tests without network/device access. Development delivery uses local core tests and a verified signed build while broader CI continues; a known failed run holds new installation. Signing and device access remain local.
