var AppController = function ($scope, $rootScope, $http, hostsManager, discoveryEvents, topologyManager) {
  $scope.topology = {
    nodes: topologyManager.nodes(),
    links: topologyManager.links(),
    current: null,
  }

  $scope.apps = null

  var start = function () {
    $scope.apps = hostsManager.apps()
    var randomNode = hostsManager.randomHost()
    var startRequest = $http.post("/disco/start", {seed: randomNode.public_dns_name})
    startRequest.success(function () {
      console.log("started")
    }).error(function () {
      console.log("already running")
    })
  }

  discoveryEvents.addEventListener("visit", function (e) {
    $scope.topology.current = topologyManager.addHost(e.data.host)
    $scope.$digest()
  })

  discoveryEvents.addEventListener("visited", function (e) {
    topologyManager.addConnections(e.data.connections)
    $scope.$digest()
  })

  discoveryEvents.addEventListener("done", function (e) {
    $scope.topology.current = null
    $scope.$digest()
  })

  hostsManager.load()
    .then(discoveryEvents.start)
    .then(start)
}