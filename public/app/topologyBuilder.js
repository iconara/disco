(function (win) {
  win.createTopologyBuilder = function (topologyManager) {
    var self = {}
    var candidates = [topologyManager.randomHost()]

    var isCandidate = function (id) {
      for (var i = 0; i < candidates.length; i++) {
        if (candidates[i].id == id) {
          return true
        }
      }
      return false
    }

    self.addNext = function () {
      if (candidates.length == 0) {
        return false
      }

      var host = candidates.shift()
      var node = {id: host.id, name: host.name, app: host.app}
      topologyManager.addNode(node, function (connectedHost) {
        if (!isCandidate(connectedHost.id)) {
          candidates.push(connectedHost)
        }
      })

      return true
    }

    return self
  }
}(window))