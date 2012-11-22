(function (win) {
  win.main = function () {
    d3.json("data/staging.json", function (topology) {
      var topologyManager = createTopologyManager(topology)
      var topologyBuilder = createTopologyBuilder(topologyManager)
      var visualizationController = createVisualizationController(d3, window, topologyManager)

      visualizationController.start()

      var intervalId = setInterval(function () {
        if (topologyBuilder.addNext()) {
          visualizationController.update()
        } else {
          clearInterval(intervalId)
        }
      }, 1000)
    })
  }
}(window))