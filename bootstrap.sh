#!/bin/bash
echo $0: starting synthetic data generation and upload to Heroku Postgres

curl https://synth.activeprime.dev/static/downloads/latest/linux/apsynth.tar.gz | tar -xz

chmod 700 ./apsynth

echo $0: beginning synth generation process
./apsynth login --license $ACTIVEPRIME_SYNTHDATA_STAGING_LICENSE


echo $0: deleting previous records
psql -c "set search_path=salesforce,public" -c "delete from account" -c "delete from lead" -c "delete from contact"  $DATABASE_URL

rm -rf /app/.apsynth/data/resources/*.zip 
rm -rf ./*.csv
rm -rf ./groupid.txt

./apsynth generate --setting $ACTIVEPRIME_SYNTHDATA_SETTINGID --resource-name "DF23"  > groupid.txt

groupid=`sed -n '2p' groupid.txt | cut -d ":" -f 2 | awk '{$1=$1};1'`

./apsynth download resources --group-id $groupid

dname=`dirname  /app/.apsynth/data/resources/*.zip`

unzip $dname/*.zip

./apsynth logout

echo $0: uploading synthdata to Heroku Postgres

accountheader=`head -n 1 account.csv`
psql -c "set search_path=salesforce,public" -c '\copy account('$accountheader') from '~/account.csv' csv header;' $DATABASE_URL

contactheader=`head -n 1 contact.csv`
psql -c "set search_path=salesforce,public" -c '\copy contact('$contactheader') from '~/contact.csv' csv header;' $DATABASE_URL

leadheader=`head -n 1 lead.csv`
psql -c "set search_path=salesforce,public" -c '\copy lead('$leadheader') from '~/lead.csv' csv header;' $DATABASE_URL

echo $0: data ready to start testing

echo $0: apsynth executed
