# aberp-bi-metabase

Metabase Installer

Summary
The purpose of this repository is to help you install Metabase Business Intelligence and configure AbilityERP (iDempiere) to make reporting much easier and more intuitive.

Launch Ubuntu Instance
  - Ec2: t2 Med, 30 gig (Min)

Instructions

Update Ubuntu 
  - sudo apt-get update

Install java and postgresql if not already installed on this server.
  - sudo apt-get --yes install openjdk-11-jdk
  - sudo apt-get --yes install postgresql postgresql-contrib phppgadmin libaprutil1-dbd-pgsql

Create a metabase folder
- sudo mkdir metabase

Clone Aberp-bi-metabse github repository
  - sudo git clone 

Execute the ...install/metabase-install.sh script to install metabase.

Execute the ...sql/update-sql.sh to create the special bi user and views in iDempiere.

Execute the ...sql/refresh-mat-view-sql.sh to update the materialized view.

You can run it via cron or via the iDempiere scheduler.
If you use iDempiere scheduler, make sure the script is owned by idempiere user.

Special Considerations
The metabase installation script assumes metabase's configuration database is installed locally 'localhost'.
If you do not like entering the password to iDempiere, you can create a ~/.pgpass file to automate the password entry.
