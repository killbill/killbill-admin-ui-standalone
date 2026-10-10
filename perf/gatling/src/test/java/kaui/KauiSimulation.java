package kaui;

import static io.gatling.javaapi.core.CoreDsl.*;
import static io.gatling.javaapi.http.HttpDsl.*;

import io.gatling.javaapi.core.*;
import io.gatling.javaapi.http.*;

import java.time.Duration;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

/**
 * Kaui load test.
 *
 * Every virtual user logs in, selects the tenant, then browses Kaui like an admin would
 * (KAUI_ITERATIONS pages with a think time in between), then leaves and is replaced by a new user
 * (closed workload model: KAUI_USERS users are active at any time).
 *
 * KAUI_SCENARIO picks what each iteration does:
 *   mix (default)     weighted mix of all the pages below, see MIX
 *   <page name>       a single page, e.g. account_show, to profile one area in isolation
 *
 * All settings are system properties (-Dkaui.users=50) or environment variables (KAUI_USERS=50); see Config.
 */
public class KauiSimulation extends Simulation {

  // ---------------------------------------------------------------------------------------------
  // Configuration
  // ---------------------------------------------------------------------------------------------

  static final class Config {
    static String get(String key, String def) {
      String v = System.getProperty("kaui." + key);
      if (v == null || v.isEmpty()) {
        v = System.getenv("KAUI_" + key.replaceAll("([a-z])([A-Z])", "$1_$2").toUpperCase());
      }
      return v == null || v.isEmpty() ? def : v;
    }

    static int getInt(String key, int def) {
      return Integer.parseInt(get(key, String.valueOf(def)));
    }

    static double getDouble(String key, double def) {
      return Double.parseDouble(get(key, String.valueOf(def)));
    }
  }

  static final String BASE_URL = Config.get("baseUrl", "http://127.0.0.1:9090");
  static final String USERNAME = Config.get("username", "admin");
  static final String PASSWORD = Config.get("password", "password");
  static final String ACCOUNTS_FILE = Config.get("accountsFile", "data/accounts.csv");
  static final String SCENARIO = Config.get("scenario", "mix");
  static final int USERS = Config.getInt("users", 10);
  static final int RAMP_SECONDS = Config.getInt("rampSeconds", 30);
  static final int DURATION_SECONDS = Config.getInt("durationSeconds", 300);
  static final int ITERATIONS = Config.getInt("iterations", 20);
  static final int THINK_MIN_MS = Config.getInt("thinkMinMs", 1000);
  static final int THINK_MAX_MS = Config.getInt("thinkMaxMs", 3000);
  static final double LARGE_ACCOUNT_PCT = Config.getDouble("largeAccountPct", 10);
  static final double MAX_ERROR_PCT = Config.getDouble("maxErrorPct", 1);
  static final boolean FETCH_RESOURCES = Boolean.parseBoolean(Config.get("fetchResources", "false"));

  // ---------------------------------------------------------------------------------------------
  // Test data (written by perf/seed/seed.py)
  // ---------------------------------------------------------------------------------------------

  static final List<Map<String, Object>> ALL_ACCOUNTS = csv(ACCOUNTS_FILE).readRecords();
  static final FeederBuilder<Object> REGULAR = accounts("regular");
  static final FeederBuilder<Object> LARGE = accounts("large");

  static FeederBuilder<Object> accounts(String profile) {
    List<Map<String, Object>> records = new ArrayList<>();
    for (Map<String, Object> r : ALL_ACCOUNTS) {
      if (profile.equals(r.get("profile"))) {
        records.add(r);
      }
    }
    // Fall back to every account so a data set without large (or regular) accounts still works
    return listFeeder(records.isEmpty() ? ALL_ACCOUNTS : records).random();
  }

  // ---------------------------------------------------------------------------------------------
  // Requests
  // ---------------------------------------------------------------------------------------------

  /** An HTML page: must not bounce back to the login page nor render Kaui's error flash. */
  static HttpRequestActionBuilder page(String name, String url) {
    return http(name).get(url).check(
        status().is(200),
        currentLocationRegex(".*/users/sign_in.*").notExists(),
        substring("id=\"flash-error\"").notExists(),
        css("meta[name='csrf-token']", "content").optional().saveAs("csrf"));
  }

  /** A DataTables JSON call: Kaui returns 200 even when the search failed, with an "error" attribute. */
  static HttpRequestActionBuilder dataTable(String name, String url, String searchValue) {
    return http(name).get(url)
        .queryParam("draw", "1")
        .queryParam("start", "0")
        .queryParam("length", "50")
        .queryParam("ordering", "desc")
        .queryParam("search[value]", searchValue)
        .queryParam("order[0][column]", "0")
        .queryParam("order[0][dir]", "asc")
        .header("Accept", "application/json")
        .header("X-Requested-With", "XMLHttpRequest")
        .check(status().is(200), jsonPath("$.error").notExists(), jsonPath("$.data").exists());
  }

  static final ChainBuilder LOGIN = exec(
      http("login_page").get("/users/sign_in")
          .check(status().is(200), css("input[name='authenticity_token']", "value").saveAs("csrf")),
      http("login").post("/users/sign_in")
          .formParam("authenticity_token", "#{csrf}")
          .formParam("user[kb_username]", USERNAME)
          .formParam("user[password]", PASSWORD)
          .check(status().is(200),
              currentLocationRegex(".*/users/sign_in.*").notExists(),
              currentLocation().saveAs("afterLogin"),
              css("meta[name='csrf-token']", "content").optional().saveAs("csrf")))
      // A user allowed on a single tenant gets it selected automatically. Otherwise Kaui shows the tenant list.
      .doIf(session -> session.getString("afterLogin").contains("/tenants")).then(
          exec(http("select_tenant").post("/tenants/select_tenant")
              .formParam("authenticity_token", "#{csrf}")
              .formParam("kb_tenant_id", "#{kb_tenant_id}")
              .check(status().is(200), currentLocationRegex(".*/tenants.*").notExists())))
      // No point browsing without a session: count the failed login and start over with a new user
      .exitHereIfFailed();

  static final Map<String, ChainBuilder> PAGES = new LinkedHashMap<>();

  static {
    PAGES.put("home", exec(page("home", "/home")));

    PAGES.put("account_search", exec(
        page("accounts_index", "/accounts"),
        http("accounts_pagination").post("/accounts/pagination.json")
            .queryParam("ordering", "desc")
            .header("X-CSRF-Token", "#{csrf}")
            .header("X-Requested-With", "XMLHttpRequest")
            .formParam("draw", "1")
            .formParam("start", "0")
            .formParam("length", "50")
            .formParam("search[value]", "#{external_key}")
            .formParam("advance_search_query", "")
            .check(status().is(200), jsonPath("$.error").notExists(), jsonPath("$.data[0]").exists())));

    PAGES.put("account_show", exec(page("account_show", "/accounts/#{account_id}")));

    PAGES.put("timeline", exec(page("account_timeline", "/accounts/#{account_id}/timeline")));

    PAGES.put("invoices", exec(
        page("account_invoices", "/accounts/#{account_id}/invoices"),
        dataTable("invoices_pagination", "/invoices/pagination.json", "#{account_id}")));

    PAGES.put("invoice_show", doIf(session -> !session.getString("invoice_id").isEmpty())
        .then(exec(page("invoice_show", "/accounts/#{account_id}/invoices/#{invoice_id}"))));

    PAGES.put("payments", exec(
        page("account_payments", "/accounts/#{account_id}/payments"),
        dataTable("payments_pagination", "/payments/pagination.json", "#{account_id}")));

    PAGES.put("payment_show", doIf(session -> !session.getString("payment_id").isEmpty())
        .then(exec(page("payment_show", "/accounts/#{account_id}/payments/#{payment_id}"))));

    PAGES.put("bundles", exec(page("account_bundles", "/accounts/#{account_id}/bundles")));

    PAGES.put("subscription_edit", doIf(session -> !session.getString("subscription_id").isEmpty())
        .then(exec(page("subscription_edit", "/subscriptions/#{subscription_id}/edit"))));
  }

  /** Weights (in %) of the "mix" scenario. */
  static final Map<String, Double> MIX = new LinkedHashMap<>();

  static {
    MIX.put("account_show", 25.0);
    MIX.put("account_search", 15.0);
    MIX.put("invoices", 15.0);
    MIX.put("payments", 10.0);
    MIX.put("timeline", 10.0);
    MIX.put("invoice_show", 8.0);
    MIX.put("payment_show", 7.0);
    MIX.put("subscription_edit", 5.0);
    MIX.put("bundles", 5.0);
  }

  // ---------------------------------------------------------------------------------------------
  // Scenario
  // ---------------------------------------------------------------------------------------------

  static ChainBuilder iteration() {
    ChainBuilder pickAccount = randomSwitchOrElse()
        .on(percent(LARGE_ACCOUNT_PCT).then(feed(LARGE)))
        .orElse(feed(REGULAR));

    ChainBuilder work;
    if ("mix".equals(SCENARIO)) {
      List<Choice.WithWeight> choices = new ArrayList<>();
      MIX.forEach((name, weight) -> choices.add(percent(weight).then(PAGES.get(name))));
      work = randomSwitch().on(choices);
    } else if (PAGES.containsKey(SCENARIO)) {
      work = PAGES.get(SCENARIO);
    } else {
      throw new IllegalArgumentException("Unknown kaui.scenario '" + SCENARIO + "', expected mix or one of " + PAGES.keySet());
    }

    ChainBuilder think = THINK_MAX_MS > 0
        ? pause(Duration.ofMillis(THINK_MIN_MS), Duration.ofMillis(THINK_MAX_MS))
        : exec(Function.identity());
    return exec(pickAccount, work, think);
  }

  final HttpProtocolBuilder httpProtocol = configureResources(http
      .baseUrl(BASE_URL)
      .acceptHeader("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
      .acceptLanguageHeader("en-US,en;q=0.5")
      .acceptEncodingHeader("gzip, deflate")
      .userAgentHeader("kaui-perf/gatling")
      // Rails sends ETags: without this, repeated URLs would be revalidated (304) and skew the numbers
      .disableCaching()
      // Propagated by Kaui to Kill Bill and logged by Tomcat's access log: lets you correlate slow requests
      .header("X-Request-Id", "#{randomUuid()}"));

  static HttpProtocolBuilder configureResources(HttpProtocolBuilder protocol) {
    // Static assets are served by Tomcat, not Rails: off by default to focus on the Rails application
    return FETCH_RESOURCES ? protocol.inferHtmlResources() : protocol;
  }

  final ScenarioBuilder scenario = scenario("kaui-" + SCENARIO)
      // A first account, for kb_tenant_id (multi-tenant users)
      .feed(REGULAR)
      .exec(LOGIN)
      .repeat(ITERATIONS).on(iteration());

  {
    setUp(scenario.injectClosed(
            rampConcurrentUsers(0).to(USERS).during(RAMP_SECONDS),
            constantConcurrentUsers(USERS).during(DURATION_SECONDS)))
        .protocols(httpProtocol)
        .maxDuration(Duration.ofSeconds(RAMP_SECONDS + DURATION_SECONDS))
        .assertions(global().failedRequests().percent().lt(MAX_ERROR_PCT));
  }
}
