var AppController = function ($scope, $rootScope, $http, hostsManager, discoveryEvents, topologyManager) {
  $scope.topology = {
    nodes: topologyManager.nodes(),
    links: topologyManager.links(),
  }

  $scope.colors = [
    "#ff8964",
    "#6f2b15",
    "#bc5837",
    "#0a6f58",
    "#37bc9e",
    "#6e431a",
    "#bb6d23",
    "#09596e",
    "#49d8ff",
    "#bb7123",
    "#6e451a",
    "#7b2ebb",
    "#cb8cff",
    "#8f2100",
    "#006566",
    "#59404f",
    "#cc5069"
  ]
  
  $scope.apps = null
  $scope.current = null

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
    $scope.current = topologyManager.addHost(e.data.host)
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