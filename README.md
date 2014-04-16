kaui-standalone
===============

Self-contained Kaui application.

Run
---

Builds are available on [Maven Central](http://search.maven.org/#search%7Cga%7C1%7Cg%3A%22org.kill-bill.billing.kaui%22%20a%3A%22kaui-standalone%22). Simply drop the war in your container of choice (e.g. Tomcat).

Make sure to install the DDL file first: https://raw.github.com/killbill/killbill-admin-ui/master/db/ddl.sql.

System properties required:

```
-Dkaui.url=http://127.0.0.1:8080
-Dkaui.api_key=bob
-Dkaui.api_secret=lazar
-Dkaui.db.url=jdbc:mysql://localhost/killbill
-Dkaui.db.username=killbill
-Dkaui.db.password=killbill
```


Build
-----

You need at least jruby-1.7.6.

The default `rake` task will create a the war:

```
bundle install && RAILS_ENV=production bundle exec rake
```


Alternatively, if you want to create a self-executable war:

```
bundle install && RAILS_ENV=production bundle exec rake assets:precompile && RAILS_ENV=production bundle exec warble executable war
```

You can then run it using:

```
java -Dkaui.url=http://127.0.0.1:8080 \
     -Dkaui.api_key=bob \
     -Dkaui.api_secret=lazar \
     -Dkaui.db.url=jdbc:mysql://localhost/killbill \
     -Dkaui.db.username=killbill \
     -Dkaui.db.password=killbill \
     -jar kaui-standalone.war --httpPort=3000
```

The startup process will be done when the following message appears:

```
INFO: Winstone Servlet Engine v0.9.10 running: controlPort=disabled
```

