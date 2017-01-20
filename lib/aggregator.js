var Aggregator = require("../build/js_module.js").class

module.exports = function(web3, env) {
  web3 = web3 || getDefaultWeb3()
  env  = env  || getDefaultEnv(web3)

  var aggregator = new Aggregator(web3, env).objects.aggregator
  var toString = function(x) { return web3.toAscii(x).replace(/\0/g, "") }

  aggregator.account = web3.eth.defaultAccount

  aggregator.inspect = function(id) {
    return {
      id:           id,

      owner:        aggregator.owner(id),
      label:        toString(aggregator.label(id)),
      minimumValid: aggregator.minimumValid(id),

      available:    aggregator.tryGet.call(id)[1],
      value:        aggregator.tryGet.call(id)[0],
    }
  }

  aggregator.filter = function(options, callback) {
    web3.eth.filter(Object.assign({
      address: aggregator.address,
    }, options), function(error, event) {
      if (error) {
        callback(error)
      } else if (!event || !event.topics) {
        callback(new Error("Bad event: " + event))
      } else {
        callback(null, web3.toDecimal(event.topics[1]))
      }
    })
  }

  return aggregator
}

function getDefaultWeb3() {
  var Web3 = require("web3")
  var HOST = process.env.ETH_RPC_HOST || "localhost"
  var PORT = process.env.ETH_RPC_PORT || 8545
  var URL  = process.env.ETH_RPC_URL  || "http://" + HOST + ":" + PORT
  var web3 = new Web3(new Web3.providers.HttpProvider(URL))

  try {
    web3.eth.coinbase
  } catch (err) {
    var message = "Could not connect to Ethereum RPC server at " + URL
    var error = new Error(message)
    error.eth_rpc_connection = true
    throw error
  }

  web3.eth.defaultAccount = process.env.ETH_ACCOUNT || web3.eth.coinbase

  return web3
}

function getDefaultEnv(web3) {
  process.env.ETH_ENV || getNetworkName(web3.version.network)
}

function getNetworkName(version) {
  if (version == 1) {
    return "live"
  } else if (version == 2) {
    return "morden"
  } else if (version == 3) {
    return "ropsten"
  } else {
    throw new Error("Unknown network version: " + version)
  }
}
