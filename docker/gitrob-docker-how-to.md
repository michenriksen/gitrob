Gitrob Docker How To
====================

* Paste your twitter key to .gitrobrc
* Got to the gitrob directory and build the gitrob container:
  `docker build -t "aykit/gitrob" .`
* Build your postgres-container or use gitrob-psql:
  `docker build -t "aykit/gitrob-psql" .`
* Start your postgres container:
  `docker run -P --name gitrob-psql aykit/gitrob-psql`
* Now, start the gitrob container with psql as link:
  `docker -run --link gitrob-psql:gitrob-psql aykit/gitrob organisation_of_choice`


Known Issues
------------

* Without interactive terminal, the gitrob container will not shut down gracefully.
  Kill it by using `docker kill container_name`
* If you use the gitrob-postgres container, be aware that it does not store
  your data in a persistent way.
* gitrob-postgres allows logins from everywhere without passphrase.
* Container names are persistent, even though the container was shut down.
  Either restart your postgres-container or delete it to start one
  with the same name.
