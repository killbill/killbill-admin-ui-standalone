kaui-standalone
===============

Self-contained Kaui application. It mounts the following engines:

* [Kaui](https://github.com/killbill/killbill-admin-ui): the core administrative UI
* The [Analytics](https://github.com/killbill/killbill-analytics-ui) UI (available when the [Analytics plugin](https://github.com/killbill/killbill-analytics-plugin) is installed)
* The [KPM](https://github.com/killbill/killbill-kpm-ui) UI (available when the [KPM plugin](https://github.com/killbill/killbill-kpm-plugin) is installed)
* The [AvaTax](https://github.com/killbill/killbill-avatax-ui) administrative module (available when the [AvaTax plugin](https://github.com/killbill/killbill-avatax-plugin) is installed)

Release builds are available on [Maven Central](http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22org.kill-bill.billing.kaui%22%20AND%20a%3A%22kaui-standalone%22) with coordinates `org.kill-bill.billing.kaui:kaui-standalone`.

Run
---

This is a standard Rails project:

```
bundle install
rails s
```

When using your own database, make sure to install the DDL file from [Kaui](https://raw.github.com/killbill/killbill-admin-ui/master/db/ddl.sql).

* Kill Bill client configuration can be found in [config/initializers/killbill_client.rb](https://github.com/killbill/killbill-admin-ui-standalone/blob/master/config/initializers/killbill_client.rb)
* Database configuration can be found in [config/database.yml](https://github.com/killbill/killbill-admin-ui-standalone/blob/master/config/database.yml)

Additionally, the project can be packaged as a self-contained war. Builds are available on [Maven Central](http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22org.kill-bill.billing.kaui%22%20a%3A%22kaui-standalone%22). Simply drop the war in your container of choice (e.g. Tomcat).

We also provide [Docker images](https://hub.docker.com/r/killbill/kaui/).

Build
-----

You need at least jruby-1.7.6.

To create a self-contained war:

```
bundle install && \
export RAILS_ENV=production && \
bundle exec rake assets:clobber assets:precompile && \
bundle exec warble
```

Alternatively, if you want to create a self-executable war:

```
bundle install && \
export RAILS_ENV=production && \
bundle exec rake assets:clobber assets:precompile && \
bundle exec warble executable war
```

You can then run it using:

```
java -Dkaui.db.adapter=jdbcmysql \
     -Dkaui.url=http://127.0.0.1:8080 \
     -Dkaui.db.url=jdbc:mysql://localhost/kaui \
     -Dkaui.db.username=killbill \
     -Dkaui.db.password=killbill \
     -Dwarbler.port=3000 \
     -jar killbill-admin-ui-standalone.war
```

The startup process will be done when the following message appears:

```
2015-10-13 18:11:43.571:INFO:oejs.Server:main: Started @25244ms
```

