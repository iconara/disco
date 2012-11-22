(function (w) {
  var COLORS = ["#ff8964", "#6f2b15", "#bc5837", "#0a6f58", "#37bc9e", "#6e431a", "#bb6d23", "#09596e", "#49d8ff", "#bb7123", "#6e451a", "#7b2ebb", "#cb8cff"]

  var colors = function (i) {
    return COLORS[i % COLORS.length]
  }

  w.createVisualizationController = function (d3, win, topologyManager) {
    var self = {}
    var svg = null
    var linksGroup = null
    var nodesGroup = null
    var labelsGroup = null
    var labelHighlightsGroup = null
    var forceLayout = null

    var width = function () {
      return win.innerWidth
    }

    var height = function () {
      return win.innerHeight
    }

    self.start = function () {
      svg = d3.select("body").append("svg:svg")
        .attr("width", width())
        .attr("height", height())

      linksGroup = svg.append("svg:g").attr("class", "links")
      nodesGroup = svg.append("svg:g").attr("class", "nodes")
      labelHighlightsGroup = svg.append("svg:g").attr("class", "labelHighlights")
      labelsGroup = svg.append("svg:g").attr("class", "labels")

      forceLayout = d3.layout.force()
        .nodes(topologyManager.nodes())
        .links(topologyManager.links())
        .linkDistance(100)
        .charge(-400)
        .size([width(), height()])
        .on("tick", layoutUpdate)

      addBlurFilter(svg.append("svg:defs"))

      win.addEventListener("resize", resizeUpdate)

      self.update()
    }

    var addBlurFilter = function (defs) {
      // magic from http://bl.ocks.org/1502762
      var filter = defs.append("svg:filter")
        .attr("id", "blur")
        .attr("filterUnits", "userSpaceOnUse")
        .attr("width", "150%")
        .attr("height", "150%");
      filter.append("svg:feGaussianBlur")
        .attr("in", "SourceGraphic")
        .attr("stdDeviation", 4)
        .attr("result", "blur-out")
      filter.append("svg:feOffset")
        .attr("in", "blur-out")
        .attr("dx", 0)
        .attr("dy", 0)
        .attr("result", "offset-out")
      filter.append("svg:feBlend")
        .attr("in", "SourceGraphic")
        .attr("in2", "offset-out")
        .attr("mode", "normal")
    }

    var resizeUpdate = function () {
      console.log("resizeUpdate")
      svg.attr("width", width()).attr("height", height())
      forceLayout.size([width(), height()])
      self.update()
    }

    var layoutUpdate = function () {
      linksGroup.selectAll(".link")
        .attr("x1", utils.pluck("source.x"))
        .attr("y1", utils.pluck("source.y"))
        .attr("x2", utils.pluck("target.x"))
        .attr("y2", utils.pluck("target.y"))

      nodesGroup.selectAll(".node")
        .attr("cx", utils.pluck("x"))
        .attr("cy", utils.pluck("y"))

      labelsGroup.selectAll(".label")
        .attr("x", utils.pluck("x"))
        .attr("y", utils.pluck("y"))

      labelHighlightsGroup.selectAll(".labelHighlight")
        .attr("x", utils.pluck("x"))
        .attr("y", utils.pluck("y"))
    }

    var nodeMouseOver = function (d) {
      var nodeFocus = function (dd) {
        return dd.id == d.id || topologyManager.areConnected(dd.id, d.id)
      }
      var labelFocus = function (dd) {}
      nodesGroup.selectAll(".node").classed("focused", nodeFocus)
      labelsGroup.selectAll(".label").classed("focused", nodeFocus)
      labelHighlightsGroup.selectAll(".labelHighlight").classed("focused", nodeFocus)
      linksGroup.selectAll(".link").classed("focused", function (dd) {
        return dd.source.id == d.id || dd.target.id == d.id
      })
    }

    var nodeMouseOut = function (d) {
      nodesGroup.selectAll(".node").classed("focused", false)
      linksGroup.selectAll(".link").classed("focused", false)
      labelsGroup.selectAll(".label").classed("focused", false)
      labelHighlightsGroup.selectAll(".labelHighlight").classed("focused", false)
    }

    self.update = function () {
      linksGroup.selectAll("line.link")
        .data(topologyManager.links(), function (d) { return [d.source.id, d.target.id].join("-") })
        .enter()
        .insert("svg:line", "circle.node")
          .attr("class", "link")

      nodesGroup.selectAll("circle.node")
        .data(topologyManager.nodes(), utils.pluck("id"))
        .enter()
        .insert("svg:circle")
          .attr("class", "node")
          .attr("r", 10)
          .attr("fill", function (d) { return colors(topologyManager.apps().indexOf(d.app)) })
          .on("mouseover", nodeMouseOver)
          .on("mouseout", nodeMouseOut)
          .call(forceLayout.drag)

      labelsGroup.selectAll("text.label")
        .data(topologyManager.nodes(), utils.pluck("id"))
        .enter()
        .insert("svg:text")
          .attr("class", "label")
          .attr("dx", 15)
          .attr("dy", 4)
          .attr("fill-opacity", 1.0)
          .text(utils.pluck("name"))
        .transition()
          .duration(3000)
          .attr("fill-opacity", 0.0)

      labelHighlightsGroup.selectAll("text.labelHighlight")
        .data(topologyManager.nodes(), utils.pluck("id"))
        .enter()
        .insert("svg:text")
          .attr("class", "labelHighlight")
          .attr("dx", 15)
          .attr("dy", 4)
          .text(utils.pluck("name"))

      forceLayout.size([width(), height()])
      forceLayout.start()
    }

    return self
  }
}(window))