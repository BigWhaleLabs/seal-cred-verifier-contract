const { sign, Point } = require('@noble/secp256k1')
const keccak256 = require('keccak256')
const fs = require('fs')

// bigendian
function bigint_to_Uint8Array(x) {
  var ret = new Uint8Array(32)
  for (var idx = 31; idx >= 0; idx--) {
    ret[idx] = Number(x % 256n)
    x = x / 256n
  }
  return ret
}

async function generateInputs() {
  // privkey, msghash, pub0, pub1
  const test_cases = []
  const proverPrivkeys = [BigInt('0x7877dF1504a7909f98c74cc30a87526F86df47cB')]

  function bigint_to_tuple(x) {
    // 2 ** 86
    let mod = 77371252455336267181195264n
    let ret = [0n, 0n, 0n]

    var x_temp = x
    for (var idx = 0; idx < 3; idx++) {
      ret[idx] = x_temp % mod
      x_temp = x_temp / mod
    }
    return ret
  }

  function bigint_to_array(n, k, x) {
    let mod = 1n
    for (var idx = 0; idx < n; idx++) {
      mod = mod * 2n
    }

    let ret = []
    var x_temp = x
    for (var idx = 0; idx < k; idx++) {
      ret.push(x_temp % mod)
      x_temp = x_temp / mod
    }
    return ret
  }

  // bigendian
  function Uint8Array_to_bigint(x) {
    var ret = 0n
    for (var idx = 0; idx < x.length; idx++) {
      ret = ret * 256n
      ret = ret + BigInt(x[idx])
    }
    return ret
  }

  for (var idx = 0; idx < proverPrivkeys.length; idx++) {
    const proverPrivkey = proverPrivkeys[idx]
    const proverPubkey = Point.fromPrivateKey(proverPrivkey)
    const msg = 'zk-airdrop'
    const msghash_bigint = Uint8Array_to_bigint(keccak256(msg)) // Needs to be basicaly some public random hardcoded value
    const msghash = bigint_to_Uint8Array(msghash_bigint)
    const sig = await sign(msghash, bigint_to_Uint8Array(proverPrivkey), {
      canonical: true,
      der: false,
    })
    const r = sig.slice(0, 32)
    const s = sig.slice(32, 64)
    var r_bigint = Uint8Array_to_bigint(r)
    var s_bigint = Uint8Array_to_bigint(s)
    var r_array = bigint_to_array(86, 3, r_bigint)
    var s_array = bigint_to_array(86, 3, s_bigint)
    var msghash_array = bigint_to_array(86, 3, msghash_bigint)
    test_cases.push([
      proverPrivkey,
      msghash_bigint,
      sig,
      proverPubkey.x,
      proverPubkey.y,
    ])
    console.log('proverPubkey x', proverPubkey.x)
    console.log('proverPubkey y', proverPubkey.y)
    console.log('s', s_bigint)
    console.log('s', s_array)
    console.log(
      'the thing',
      bigint_to_array(
        86,
        3,
        57896044618658097711785492504343953926418782139537452191302581570759080747168n
      )
    )
    console.log('msghash', msghash)

    const json = JSON.stringify(
      {
        r: r_array.map((x) => x.toString()),
        s: s_array.map((x) => x.toString()),
        msghash: msghash_array.map((x) => x.toString()),
        pubkey: [
          bigint_to_tuple(proverPubkey.x).map((x) => x.toString()),
          bigint_to_tuple(proverPubkey.y).map((x) => x.toString()),
        ],
      },
      null,
      '\t'
    )
    console.log(json)
    fs.writeFile(
      './inputs/input_verify' + idx.toString() + '.json',
      json,
      'utf8',
      function (err) {
        if (err) throw err
        console.log('Saved!')
      }
    )
  }
}

generateInputs()
