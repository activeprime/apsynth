#!/bin/bash
echo $0: starting bootstrap process

curl https://synth.activeprime.dev/static/downloads/latest/linux/apsynth.tar.gz | tar -xz

chmod 700 ./apsynth

echo $0: beginning synth generation process
./apsynth login --license $ACTIVEPRIME_SYNTHDATA_STAGING_LICENSE

echo $0: deleting Heroku Postgres records
psql $DATABASE_URL -c "set search_path = salesforce,public; delete from account; delete from contact;" 

curl https://raw.githubusercontent.com/activeprime/apsynth/internal-test/setting.json --output setting.json

tempsetting=`./apsynth upload --file setting.json --setting-name Setting` 
settingid=`echo $tempsetting | cut -d ":" -f 2 | awk '{$1=$1};1' | sed $'s/\e\\[[0-9;:]*[a-zA-Z]//g'`

./apsynth generate --setting $settingid --resource-name "HerokuSynth" > groupid.txt

groupid=`sed -n '2p' groupid.txt | cut -d ":" -f 2 | awk '{$1=$1};1'`

rm -rf /app/.apsynth/data/resources/*.zip 

./apsynth download resources --group-id $groupid

dname=`dirname  /app/.apsynth/data/resources/*.zip`

unzip $dname/*.zip

./apsynth logout

echo $0: uploading synthdata to Heroku Postgres
psql -c "set search_path = salesforce,public;" -c '\copy account(billingcity,name,isdeleted,systemmodstamp,billingpostalcode,createddate,billingstate,ext_id_heroku__c,billingcountry,billingstreet) from '~/account.csv' csv header;' $DATABASE_URL
psql -c "set search_path = salesforce,public;" -c '\copy contact(firstname,lastname,phone,ext_id_heroku__c,account__ext_id_heroku__c) from '~/contact.csv' csv header;' $DATABASE_URL


echo $0: data ready to start testing
