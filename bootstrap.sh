  echo $0: starting synthetic data generation and upload to Heroku Postgres

	curl https://synth.activeprime.dev/static/downloads/latest/linux/apsynth.tar.gz | tar -xz

	chmod 700 ./apsynth

	echo $0: beginning synth generation process
	./apsynth login --license $ACTIVEPRIME_SYNTHDATA_STAGING_LICENSE


	rm -rf /app/.apsynth/data/resources/*.zip 

	./apsynth download resources --group-id $ACTIVEPRIME_SYNTHDATA_GROUPID

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
