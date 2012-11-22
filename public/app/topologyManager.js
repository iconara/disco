(function (win) {
  win.createTopologyManager = function (topology) {
    var self = {}
    var apps = utils.uniq(topology.hosts.map(utils.pluck("app")))
    var nodes = []
    var links = []

    self.nodes = function () { return nodes }
    self.links = function () { return links }
    self.apps = function () { return apps }

    self.randomHost = function () {
      return topology.hosts[Math.floor(Math.random() * topology.hosts.length)]
    }

    self.areConnected = function (id1, id2) {
      for (var i = 0; i < topology.connections.length; i++) {
        var c = topology.connections[i]
        if ((c.source == id1 && c.target == id2) || (c.source == id2 && c.target == id1)) {
          return true
        }
      }
      return false
    }

    var findHost = function (id) {
      for (var i = 0; i < topology.hosts.length; i++) {
        if (topology.hosts[i].id == id) {
          return topology.hosts[i]
        }
      }
      return null
    }

    var findNodeIndex = function (id) {
      for (var i = 0; i < nodes.length; i++) {
        if (nodes[i].id == id) {
          return i
        }
      }
      return -1
    }

    var eachConnection = function (block) {
      topology.connections.forEach(block)
    }

    self.addNode = function (node, connectionsListener) {
      eachConnection(function (connection) {
        var link = {target: -1, source: -1}
        if (connection.target == node.id) {
          link.target = nodes.length
          link.source = findNodeIndex(connection.source)
        } else if (connection.source == node.id) {
          link.target = findNodeIndex(connection.target)
          link.source = nodes.length
        }
        if (link.source != -1 && link.target != -1) {
          links.push(link)
        } else if (link.source != -1) {
          var host = findHost(connection.target)
          if (host != null && connectionsListener != null) {
            connectionsListener(host)
          }
        } else if (link.target != -1) {
          var host = findHost(connection.source)
          if (host != null && connectionsListener != null) {
            connectionsListener(host)
          }
        }
      })
      nodes.push(node)
    }

    return self
  }
}(window))