(function () {
  // Prefixes of cookies that belong to this app (kaui).
  // Any cookie whose name does NOT start with one of these will be deleted.
  var KNOWN_PREFIXES = [
    '_kaui',
    'remember_user_token',
    '_csrf',
    'authenticity_token',
    'jwt_token',
    'avt_'
  ];

  // Optional: parent domain to also target when deleting broad-scoped cookies
  // (e.g. cookies originally set with domain=.killbill.io).
  // Set window.KAUI_PARENT_DOMAIN from your ERB layout if needed:
  //   <script>window.KAUI_PARENT_DOMAIN = "<%= ENV['KAUI_PARENT_DOMAIN'] %>";</script>
  var parentDomain = window.KAUI_PARENT_DOMAIN || null;

  function isKnown(name) {
    return KNOWN_PREFIXES.some(function (prefix) {
      return name.indexOf(prefix) === 0;
    });
  }

  function expireCookie(name, domain) {
    var base = name + '=; expires=Thu, 01 Jan 1970 00:00:00 GMT; path=/';
    document.cookie = domain ? base + '; domain=' + domain : base;
  }

  function purgeForeignCookies() {
    var cookies = document.cookie.split(';');
    cookies.forEach(function (c) {
      var name = c.trim().split('=')[0];
      if (name && !isKnown(name)) {
        expireCookie(name);                      // bare host scope
        if (parentDomain) {
          expireCookie(name, parentDomain);      // broad .killbill.io scope
        }
      }
    });
  }

  var LOGIN_PATH = '/users/sign_in';
  if (window.location.pathname === LOGIN_PATH) {
    purgeForeignCookies();
  }
})();
