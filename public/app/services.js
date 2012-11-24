(function () {
  var parseApp = function (hostName) {
    var matchData = hostName.match(/^(?:prod|staging)(.+?)\d+\.byburt\.com$/)
    if (matchData) {
      return matchData[1]
    } else {
      return null
    }
  }

  var discoModule = angular.module("disco")

  discoModule.factory("discoveryEvents", function ($window) {
    var self = {}
    var events = null
    var listeners = {}

    var dispatchEvent = function (event, data) {
      if (listeners[event]) {
        listeners[event].forEach(function (listener) {
          listener({type: event, data: data})
        })
      }
    }

    self.start = function () {
      events = new $window.EventSource("/events")
      ;["visit", "visited", "done"].forEach(function (eventName) {
        events.addEventListener(eventName, function (e) {
          dispatchEvent(eventName, JSON.parse(e.data))
        })
      })
    }

    self.addEventListener = function (event, listener) {
      if (listeners[event] == undefined) {
        listeners[event] = []
      }
      listeners[event].push(listener)
    }

    return self
  })

  discoModule.factory("hostsManager", function ($http, $q) {
    var self = {}
    var hosts = []

    self.load = function () {
      var loadDeferred = $q.defer()
      $http.get("/hosts")
        .then(function (response) {
          hosts = response.data
          return self
        })
        .then(loadDeferred.resolve, loadDeferred.reject)
      return loadDeferred.promise
    }

    self.randomHost = function () {
      return hosts[Math.floor(Math.random() * hosts.length)]
    }

    self.apps = function () {
      return hosts.map(function (host) { return parseApp(host.tags.Name) })
    }

    return self
  })

  discoModule.factory("topologyManager", function () {
    var self = {}
    var hosts = []
    var hostsById = {}
    var connections = []
    var nodes = []
    var nodesById = {}
    var links = []
    var linksBySource = {}
    var linksByTarget = {}

    self.nodes = function () { return nodes }
    self.links = function () { return links }
    self.apps = function () { return [] }

    self.areConnected = function (id1, id2) {
      return connectionsBySource[id1].some(function (connection) { return connection.id == id2 }) || connectionsBySource[id2].some(function (connection) { return connection.id == id1 })
    }

    var addNodeFromHost = function (host) {
      var node = {
        id: host.instance_id,
        name: host.tags.Name,
        app: parseApp(host.tags.Name),
        index: nodes.length
      }

      nodes.push(node)
      nodesById[node.id] = node

      addLinksFromNode(node)

      return node
    }

    var addLinksFromNode = function (node) {
      if (node.id in linksByTarget) {
        linksByTarget[node.id].forEach(function (link) {
          var sourceNode = nodesById[node.id]
          var targetNode = nodes[link.target]
          createLink(sourceNode, targetNode)
        })
      }
      if (node.id in linksBySource) {
        linksBySource[node.id].forEach(function (link) {
          var sourceNode = nodes[link.source]
          var targetNode = nodesById[node.id]
          createLink(sourceNode, targetNode)
        })
      }
    }

    var linkExists = function (sourceNode, targetNode) {
      return links.some(function (link) {
        return (link.source == sourceNode.index && link.target == targetNode.index) ||
              (link.source == targetNode.index && link.target == sourceNode.index)
      })
    }

    var createLink = function (sourceNode, targetNode) {
      if (!linkExists(sourceNode, targetNode)) {
        var link = {source: sourceNode.index, target: targetNode.index}
        links.push(link)

        if (!(sourceNode.id in linksBySource)) {
          linksBySource[sourceNode.id] = []
        }
        if(!(targetNode.id in linksByTarget)) {
          linksByTarget[targetNode.id] = []
        }

        linksBySource[sourceNode.id].push(link)
        linksByTarget[targetNode.id].push(link)
      }
    }

    self.addHost = function (host) {
      if (!(host.instance_id in hostsById)) {
        hosts.push(host)
        hostsById[host.instance_id] = host
        return addNodeFromHost(host)
      }
      return nodesById[host.instance_id]
    }

    self.addConnections = function (conns) {
      conns.forEach(function (connection) {
        self.addHost(connection.upstream_host)
        self.addHost(connection.downstream_host)

        var sourceNode = nodesById[connection.upstream_host.instance_id]
        var targetNode = nodesById[connection.downstream_host.instance_id]

        if (sourceNode && targetNode) {
          createLink(sourceNode, targetNode)
        }
      })
      connections = connections.concat(conns)
    }

    return self
  })

  angular.module("d3").factory("d3", function ($window) {
    return $window.d3
  })
}())