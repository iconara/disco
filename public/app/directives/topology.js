(function () {
  var discoModule = angular.module("disco")

  discoModule.directive("topology", function (d3, $window) {
    return {
      restrict: "E",
      template: '<div></div>',
      replace: true,
      link: function(scope, element, attrs) {
        var currentNode = null
        var apps = []
        var allColors = []
        var colors = function (i) { return "white" }

        scope.$watch(attrs.nodes, function (newNodes) {
          forceLayout.nodes(newNodes)
          update()
        }, true)
        
        scope.$watch(attrs.links, function (newLinks) {
          forceLayout.links(newLinks)
          update()
        }, true)

        scope.$watch(attrs.current, function (newCurrentNode) {
          currentNode = newCurrentNode
          update()
        }, true)

        scope.$watch(attrs.apps, function (newApps) {
          apps = newApps || []
          updateColors()
          update()
        })

        scope.$watch(attrs.colors, function (newColors) {
          if (newColors) {
            allColors = newColors.map(function (c) { return {color: c} })
            colors = function (i) { return allColors[i % allColors.length].color }
          }
          updateColors()
          update()
        })

        var svg = null
        var linksGroup = null
        var nodesGroup = null
        var labelsGroup = null
        var labelHighlightsGroup = null
        var forceLayout = null

        var width = function () { return element.parent()[0].offsetWidth }

        var height = function () { return element.parent()[0].offsetHeight }

        var start = function () {
          svg = d3.select(element[0]).append("svg:svg")
            .attr("width", width())
            .attr("height", height())

          linksGroup = svg.append("svg:g").attr("class", "links")
          nodesGroup = svg.append("svg:g").attr("class", "nodes")
          labelHighlightsGroup = svg.append("svg:g").attr("class", "labelHighlights")
          labelsGroup = svg.append("svg:g").attr("class", "labels")

          forceLayout = d3.layout.force()
            .linkDistance(100)
            .charge(-400)
            .size([width(), height()])
            .on("tick", layoutUpdate)

          addBlurFilter(svg.append("svg:defs"))

          $window.addEventListener("resize", resizeUpdate)

          update()
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

        var pluck = function (property) {
          var components = property.split(".")
          return function (obj) {
            var o = obj
            for (var i = 0; i < components.length; i++) {
              o = o[components[i]]
            }
            return o
          }
        }

        var updateColors = function () {
          if (allColors) {
            var colorsGroup = svg.select("g.colors")

            if (colorsGroup.empty()) {
              colorsGroup = svg.insert("svg:g").attr("class", "colors")
            }
            
            var nodeWidth = width()/allColors.length
            var nodeHeight = 10
            var selectedHeight = 30

            colorsGroup.attr("transform", "translate(0, " + (height() - selectedHeight) + ")")

            var colorNodes = colorsGroup.selectAll("rect.color")
              .data(allColors, function (d) { return d.color })

            var textNodes = colorsGroup.selectAll("text.app")
              .data(apps, function (d) { return d })

            colorNodes.enter()
              .insert("rect")
              .attr("class", "color")
              .on("mouseover", function (d) { d.selected = true; updateColors() })
              .on("mouseout", function (d) { d.selected = false; updateColors() })

            textNodes.enter()
              .insert("text")
              .attr("class", "app")

            colorNodes
              .attr("x", function (d, i) { return i * nodeWidth })
              .attr("y", function (d, i) { return d.selected ? 0 : selectedHeight - nodeHeight })
              .attr("width", function (d) { return nodeWidth })
              .attr("height", function (d) { return d.selected ? selectedHeight : nodeHeight })
              .attr("fill", function (d, i) { return colors(i) })

            textNodes
              .attr("x", function (d, i) { return (i % allColors.length) * nodeWidth })
              .attr("y", function (d, i) { return -5 })
              .attr("dy", function (d, i) { return -12 * Math.floor(i/allColors.length) })
              .attr("display", function (d, i) { return allColors[i % allColors.length].selected ? "block" : "none" })
              .text(function (d) { return d })
          }
        }

        var resizeUpdate = function () {
          svg.attr("width", width()).attr("height", height())
          forceLayout.size([width(), height()])
          updateColors()
          update()
        }

        var layoutUpdate = function () {
          linksGroup.selectAll(".link")
            .attr("x1", pluck("source.x"))
            .attr("y1", pluck("source.y"))
            .attr("x2", pluck("target.x"))
            .attr("y2", pluck("target.y"))

          nodesGroup.selectAll(".node")
            .attr("cx", pluck("x"))
            .attr("cy", pluck("y"))
            .attr("fill", function (d) { return colors(apps.indexOf(d.app)) })
            .classed("current", function (d) { return currentNode && currentNode.id == d.id })

          labelsGroup.selectAll(".label")
            .attr("x", pluck("x"))
            .attr("y", pluck("y"))

          labelHighlightsGroup.selectAll(".labelHighlight")
            .attr("x", pluck("x"))
            .attr("y", pluck("y"))
        }

        var areConnected = function(n1, n2) {
          return forceLayout.links().some(function (link) {
            return (link.source.id == n1.id && link.target.id == n2.id) ||
                   (link.source.id == n2.id && link.target.id == n1.id)
          })
        }

        var nodeMouseOver = function (d) {
          var nodeFocus = function (dd) {
            return dd.id == d.id || areConnected(dd, d)
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

        var update = function () {
          linksGroup.selectAll("line.link")
            .data(forceLayout.links(), function (d) { return [d.source.id, d.target.id].join("-") })
            .enter()
            .insert("svg:line", "circle.node")
              .attr("class", "link")

          nodesGroup.selectAll("circle.node")
            .data(forceLayout.nodes(), pluck("id"))
            .enter()
            .insert("svg:circle")
              .attr("class", "node")
              .attr("r", 10)
              .on("mouseover", nodeMouseOver)
              .on("mouseout", nodeMouseOut)
              .call(forceLayout.drag)

          labelsGroup.selectAll("text.label")
            .data(forceLayout.nodes(), pluck("id"))
            .enter()
            .insert("svg:text")
              .attr("class", "label")
              .attr("dx", 15)
              .attr("dy", 4)
              .attr("fill-opacity", 1.0)
              .text(pluck("name"))
            .transition()
              .delay(5000)
              .duration(3000)
              .attr("fill-opacity", 0.0)

          labelHighlightsGroup.selectAll("text.labelHighlight")
            .data(forceLayout.nodes(), pluck("id"))
            .enter()
            .insert("svg:text")
              .attr("class", "labelHighlight")
              .attr("dx", 15)
              .attr("dy", 4)
              .text(pluck("name"))

          forceLayout.size([width(), height()])
          forceLayout.start()
        }

        start()
      }
    }
  })
}())