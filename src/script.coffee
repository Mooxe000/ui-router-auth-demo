angular.module 'demo', [
  'ui.router'
  'ui.bootstrap'
]

.factory 'principal', [
  '$q'
  '$http'
  '$timeout'
  (
    $q
    $http
    $timeout
  ) ->
    _identity = undefined
    _authenticated = false

    isIdentityResolved: ->
      angular.isDefined _identity
    isAuthenticated: ->
      _authenticated
    isInRole: (role) ->
      if !_authenticated or !_identity.roles
        return false
      _identity.roles.indexOf(role) != -1
    isInAnyRole: (roles) ->
      if !_authenticated or !_identity.roles
        return false
      i = 0
      while i < roles.length
        if @isInRole(roles[i])
          return true
        i++
      false
    authenticate: (identity) ->
      _identity = identity
      _authenticated = identity != null
      # for this demo, we'll store the identity in localStorage. For you, it could be a cookie, sessionStorage, whatever
      if identity
        localStorage.setItem 'demo.identity', angular.toJson(identity)
      else
        localStorage.removeItem 'demo.identity'
      return
    identity: (force) ->
      deferred = $q.defer()
      if force == true
        _identity = undefined
      # check and see if we have retrieved the identity data from the server. if we have, reuse it by immediately resolving
      if angular.isDefined(_identity)
        deferred.resolve _identity
        return deferred.promise
      # otherwise, retrieve the identity data from the server, update the identity object, and then resolve.
      #                   $http.get('/svc/account/identity', { ignoreErrors: true })
      #                        .success(function(data) {
      #                            _identity = data;
      #                            _authenticated = true;
      #                            deferred.resolve(_identity);
      #                        })
      #                        .error(function () {
      #                            _identity = null;
      #                            _authenticated = false;
      #                            deferred.resolve(_identity);
      #                        });
      # for the sake of the demo, we'll attempt to read the identity from localStorage. the example above might be a way if you use cookies or need to retrieve the latest identity from an api
      # i put it in a timeout to illustrate deferred resolution
      self = @
      $timeout ->
        _identity = angular.fromJson(localStorage.getItem('demo.identity'))
        self.authenticate _identity
        deferred.resolve _identity
        return
      , 1000
      deferred.promise
]

.factory 'authorization', [
  '$rootScope'
  '$state'
  'principal'
  (
    $rootScope
    $state
    principal
  ) ->
    authorize: ->
      principal.identity().then ->
        isAuthenticated = principal.isAuthenticated()
        if $rootScope.toState.data.roles and $rootScope.toState.data.roles.length > 0 and !principal.isInAnyRole($rootScope.toState.data.roles)
          if isAuthenticated
            $state.go 'accessdenied'
          else
            # user is not authenticated. stow the state they wanted before you
            # send them to the signin state, so you can return them when you're done
            $rootScope.returnToState = $rootScope.toState
            $rootScope.returnToStateParams = $rootScope.toStateParams
            # now, send them to the signin state so they can log in
            $state.go 'signin'
        return
]

.controller 'SigninCtrl', [
  '$scope'
  '$state'
  'principal'
  (
    $scope
    $state
    principal
  ) ->
    $scope.signin = ->
      # here, we fake authenticating and give a fake user
      principal.authenticate
        name: 'Test User'
        roles: [ 'User' ]
      if $scope.returnToState
        $state.go $scope.returnToState.name, $scope.returnToStateParams
      else
        $state.go 'home'
      return
    return
]

.controller 'HomeCtrl', [
  '$scope'
  '$state'
  'principal'
  (
    $scope
    $state
    principal
  ) ->
    $scope.signout = ->
      principal.authenticate null
      $state.go 'signin'
      return
    return
]

.config [
  '$stateProvider'
  '$urlRouterProvider'
  (
    $stateProvider
    $urlRouterProvider
  ) ->
    $urlRouterProvider.otherwise '/'
    $stateProvider
    .state 'site',
      'abstract': true
      resolve:
        authorize: [
          'authorization'
          (
            authorization
          ) ->
            authorization.authorize()
        ]

    .state 'home',
      parent: 'site'
      url: '/'
      data:
        roles: [
          'User'
        ]
      views:
        'content@':
          templateUrl: 'home.html'
          controller: 'HomeCtrl'

    .state 'signin',
      parent: 'site'
      url: '/signin'
      data:
        roles: []
      views:
        'content@':
          templateUrl: 'signin.html'
          controller: 'SigninCtrl'

    .state 'restricted',
      parent: 'site'
      url: '/restricted'
      data:
        roles: [
          'Admin'
        ]
      views:
        'content@':
          templateUrl: 'restricted.html'

    .state 'accessdenied',
      parent: 'site'
      url: '/denied'
      data:
        roles: []
      views:
        'content@':
          templateUrl: 'denied.html'
    return
]

.run [
  '$rootScope'
  '$state'
  '$stateParams'
  'authorization'
  'principal'
  (
    $rootScope
    $state
    $stateParams
    authorization
    principal
  ) ->
    $rootScope
    .$on '$stateChangeStart'
    , (event, toState, toStateParams) ->
      $rootScope.toState = toState
      $rootScope.toStateParams = toStateParams
      authorization.authorize() if principal.isIdentityResolved()
      return
    return
]

# ---
# generated by js2coffee 2.0.1