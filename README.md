# aberp-bi-metabase

Metabase Installer

Summary
The purpose of this repository is to help you install Metabase Business Intelligence and configure AbilityERP (iDempiere) to make reporting much easier and more intuitive.

Launch Ubuntu Instance
  - Ec2: t2 Med, 30 gig (Min)

# Instructions

Update Ubuntu 
  - sudo apt-get update

Install java and postgresql if not already installed on this server.
  - sudo apt-get --yes install openjdk-11-jdk
  - sudo apt-get --yes install postgresql postgresql-contrib phppgadmin libaprutil1-dbd-pgsql

Create a metabase install folder on home dir
  - sudo mkdir metabaseinstall

Clone Aberp-bi-metabase github repository
  - Go to folder metabaseinstall
  - sudo git clone https://github.com/AdamSawtell/aberp-bi-metabase.git

Make the scripts excutable - All. Need to do by folder
  - sudo chmod +x *

Execute the ...install/metabase-install.sh script to install metabase.
  - sudo ./metabase-install.sh

Metabase will be available via HTTP on you Ip
Make sure you have managed security groups on your server!

# Create the connection between Metabase and AbilityERP (iDempiere)

Log into AbilityERP (iDempiere) Bash
- Create a new folder im /OPT/ folder called metabase
- sudo mkdir metabase
- Go to folder

Clone the Aberp-bi-metabase/sql scripts from github
  - sudo git clone https://github.com/AdamSawtell/aberp-bi-metabase.git sql

Make the scripts in sql folder excutable
  - sudo chmod +x *

Execute the ...sql/update-sql.sh to create the special bi user and views in AbilityERP (iDempiere)
  - Run the update-sql.sh
  - ./update-sql.sh

Execute the ...sql/refresh-mat-view-sql.sh to update the materialized view.

# You can run it via cron or via the iDempiere scheduler (Example below is daily)
  - crontab -e
  - 0 0 * * * /opt/metabase/sql/sql/refresh-mat-view-sql.sh

# If you use iDempiere scheduler, make sure the script is owned by idempiere user.

Special Considerations
The metabase installation script assumes metabase's configuration database is installed locally 'localhost'.
If you do not like entering the password to iDempiere, you can create a ~/.pgpass file to automate the password entry.
