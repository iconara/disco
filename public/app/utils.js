(function (win) {
  var uniq = function (list) {
    var uniqueList = []
    var lastItem = null
    list.sort().forEach(function (item) {
      if (item != lastItem) {
        uniqueList.push(item)
      }
    })
    return uniqueList
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

  win.utils = {
    uniq: uniq,
    pluck: pluck
  }
}(window))