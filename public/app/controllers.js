var AppController = function ($scope, $rootScope, $http, hostsManager, discoveryEvents, topologyManager) {
  $scope.topology = {
    nodes: topologyManager.nodes(),
    links: topologyManager.links()
  }

  var start = function () {
    var randomNode = hostsManager.randomHost()
    var startRequest = $http.post("/disco/start", {seed: randomNode.public_dns_name})
    startRequest.success(function () {
      console.log("started")
    }).error(function () {
      console.log("already running")
    })
  }

  discoveryEvents.addEventListener("visit", function (e) {
    topologyManager.addHost(e.data.host)
    $scope.$digest()
  })

  discoveryEvents.addEventListener("visited", function (e) {
    topologyManager.addConnections(e.data.connections)
    $scope.$digest()
  })

  hostsManager.load()
    .then(discoveryEvents.start)
    .then(start)
}