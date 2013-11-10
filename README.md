kaui-standalone
===============

Self-contained Kaui application.

Run
---

Make sure to install the DDL file first: https://raw.github.com/killbill/killbill-admin-ui/master/db/ddl.sql.

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

Build
-----

You need at least jruby-1.7.6.

```
bundle install && bundle exec rake
```
