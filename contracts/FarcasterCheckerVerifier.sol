//
// Copyright 2017 Christian Reitwiessner
// Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
// The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//
// 2019 OKIMS
//      ported to solidity 0.6
//      fixed linter warnings
//      added requiere error messages
//
//
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.16;

import "@big-whale-labs/versioned-contract/contracts/Versioned.sol";

library Pairing {
  struct G1Point {
    uint256 X;
    uint256 Y;
  }
  // Encoding of field elements is: X[0] * z + X[1]
  struct G2Point {
    uint256[2] X;
    uint256[2] Y;
  }

  /// @return the generator of G1
  function P1() internal pure returns (G1Point memory) {
    return G1Point(1, 2);
  }

  /// @return the generator of G2
  function P2() internal pure returns (G2Point memory) {
    // Original code point
    return
      G2Point(
        [
          11559732032986387107991004021392285783925812861821192530917403151452391805634,
          10857046999023057135944570762232829481370756359578518086990519993285655852781
        ],
        [
          4082367875863433681332203403145435568316851327593401208105741076214120093531,
          8495653923123431417604973247489272438418190587263600148770280649306958101930
        ]
      );

    /*
        // Changed by Jordi point
        return G2Point(
            [10857046999023057135944570762232829481370756359578518086990519993285655852781,
             11559732032986387107991004021392285783925812861821192530917403151452391805634],
            [8495653923123431417604973247489272438418190587263600148770280649306958101930,
             4082367875863433681332203403145435568316851327593401208105741076214120093531]
        );
*/
  }

  /// @return r the negation of p, i.e. p.addition(p.negate()) should be zero.
  function negate(G1Point memory p) internal pure returns (G1Point memory r) {
    // The prime q in the base field F_q for G1
    uint256 q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
    if (p.X == 0 && p.Y == 0) return G1Point(0, 0);
    return G1Point(p.X, q - (p.Y % q));
  }

  /// @return r the sum of two points of G1
  function addition(G1Point memory p1, G1Point memory p2)
    internal
    view
    returns (G1Point memory r)
  {
    uint256[4] memory input;
    input[0] = p1.X;
    input[1] = p1.Y;
    input[2] = p2.X;
    input[3] = p2.Y;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, "pairing-add-failed");
  }

  /// @return r the product of a point on G1 and a scalar, i.e.
  /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
  function scalar_mul(G1Point memory p, uint256 s)
    internal
    view
    returns (G1Point memory r)
  {
    uint256[3] memory input;
    input[0] = p.X;
    input[1] = p.Y;
    input[2] = s;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, "pairing-mul-failed");
  }

  /// @return the result of computing the pairing check
  /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
  /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
  /// return true.
  function pairing(G1Point[] memory p1, G2Point[] memory p2)
    internal
    view
    returns (bool)
  {
    require(p1.length == p2.length, "pairing-lengths-failed");
    uint256 elements = p1.length;
    uint256 inputSize = elements * 6;
    uint256[] memory input = new uint256[](inputSize);
    for (uint256 i = 0; i < elements; i++) {
      input[i * 6 + 0] = p1[i].X;
      input[i * 6 + 1] = p1[i].Y;
      input[i * 6 + 2] = p2[i].X[0];
      input[i * 6 + 3] = p2[i].X[1];
      input[i * 6 + 4] = p2[i].Y[0];
      input[i * 6 + 5] = p2[i].Y[1];
    }
    uint256[1] memory out;
    bool success;
    // solium-disable-next-line security/no-inline-assembly
    assembly {
      success := staticcall(
        sub(gas(), 2000),
        8,
        add(input, 0x20),
        mul(inputSize, 0x20),
        out,
        0x20
      )
      // Use "invalid" to make gas estimation work
      switch success
      case 0 {
        invalid()
      }
    }
    require(success, "pairing-opcode-failed");
    return out[0] != 0;
  }

  /// Convenience method for a pairing check for two pairs.
  function pairingProd2(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2
  ) internal view returns (bool) {
    G1Point[] memory p1 = new G1Point[](2);
    G2Point[] memory p2 = new G2Point[](2);
    p1[0] = a1;
    p1[1] = b1;
    p2[0] = a2;
    p2[1] = b2;
    return pairing(p1, p2);
  }

  /// Convenience method for a pairing check for three pairs.
  function pairingProd3(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2
  ) internal view returns (bool) {
    G1Point[] memory p1 = new G1Point[](3);
    G2Point[] memory p2 = new G2Point[](3);
    p1[0] = a1;
    p1[1] = b1;
    p1[2] = c1;
    p2[0] = a2;
    p2[1] = b2;
    p2[2] = c2;
    return pairing(p1, p2);
  }

  /// Convenience method for a pairing check for four pairs.
  function pairingProd4(
    G1Point memory a1,
    G2Point memory a2,
    G1Point memory b1,
    G2Point memory b2,
    G1Point memory c1,
    G2Point memory c2,
    G1Point memory d1,
    G2Point memory d2
  ) internal view returns (bool) {
    G1Point[] memory p1 = new G1Point[](4);
    G2Point[] memory p2 = new G2Point[](4);
    p1[0] = a1;
    p1[1] = b1;
    p1[2] = c1;
    p1[3] = d1;
    p2[0] = a2;
    p2[1] = b2;
    p2[2] = c2;
    p2[3] = d2;
    return pairing(p1, p2);
  }
}

contract FarcasterCheckerVerifier is Versioned {
  constructor(string memory _version) Versioned(_version) {}

  using Pairing for *;
  struct VerifyingKey {
    Pairing.G1Point alfa1;
    Pairing.G2Point beta2;
    Pairing.G2Point gamma2;
    Pairing.G2Point delta2;
    Pairing.G1Point[] IC;
  }
  struct Proof {
    Pairing.G1Point A;
    Pairing.G2Point B;
    Pairing.G1Point C;
  }

  function verifyingKey() internal pure returns (VerifyingKey memory vk) {
    vk.alfa1 = Pairing.G1Point(
      20491192805390485299153009773594534940189261866228447918068658471970481763042,
      9383485363053290200918347156157836566562967994039712273449902621266178545958
    );

    vk.beta2 = Pairing.G2Point(
      [
        4252822878758300859123897981450591353533073413197771768651442665752259397132,
        6375614351688725206403948262868962793625744043794305715222011528459656738731
      ],
      [
        21847035105528745403288232691147584728191162732299865338377159692350059136679,
        10505242626370262277552901082094356697409835680220590971873171140371331206856
      ]
    );
    vk.gamma2 = Pairing.G2Point(
      [
        11559732032986387107991004021392285783925812861821192530917403151452391805634,
        10857046999023057135944570762232829481370756359578518086990519993285655852781
      ],
      [
        4082367875863433681332203403145435568316851327593401208105741076214120093531,
        8495653923123431417604973247489272438418190587263600148770280649306958101930
      ]
    );
    vk.delta2 = Pairing.G2Point(
      [
        12599857379517512478445603412764121041984228075771497593287716170335433683702,
        7912208710313447447762395792098481825752520616755888860068004689933335666613
      ],
      [
        11502426145685875357967720478366491326865907869902181704031346886834786027007,
        21679208693936337484429571887537508926366191105267550375038502782696042114705
      ]
    );
    vk.IC = new Pairing.G1Point[](13);

    vk.IC[0] = Pairing.G1Point(
      19787899393236938727853028198426819148509001327258795953090133434611409393086,
      19907170380701208073450091175750366772410118559431008969987187603956170133978
    );

    vk.IC[1] = Pairing.G1Point(
      12327786056758895409800196864153918120714498263309903641498259131892761194713,
      1144890684681150287375259724185065165692026230775984158391211526458194555971
    );

    vk.IC[2] = Pairing.G1Point(
      3815391197215775887173943648454353269925449326010410795657690774362549377237,
      6721547255247532547558246552900962967712944630768022964811514657213913321821
    );

    vk.IC[3] = Pairing.G1Point(
      19391681165958221554159954281342300071840613129630424969463973526392405568645,
      10443557482775616864910320308925911955022928137760225909091605045422988491073
    );

    vk.IC[4] = Pairing.G1Point(
      11510957786527798894566590030197916149830534038933376549247053575332392502091,
      11084142064040841064440381632635806400496315986044859797566004045357106250556
    );

    vk.IC[5] = Pairing.G1Point(
      8499961558557527122592854850722044865940309564019292177073653273388720520873,
      9877344702538305576062189300984148242634308451543229914667765217106354448926
    );

    vk.IC[6] = Pairing.G1Point(
      10256429011452312838975450718645197577732697734464993202580236489018958548766,
      14876690670078670372183942917221788271032652589375685982991824584025000123426
    );

    vk.IC[7] = Pairing.G1Point(
      16873247581593234473903211714534229363035211869127378843441406838581676139554,
      15237402962832073857191428754217893120396430620466455335253897136189360971166
    );

    vk.IC[8] = Pairing.G1Point(
      20365042107845738470920877249459789600331569301036843420594578378641564302868,
      8173908785985683251024695919333811874160741190017859521311674872523726700367
    );

    vk.IC[9] = Pairing.G1Point(
      2993926041470677332333247063443660444457076465747589950188315012981077453269,
      1540396674926443218137212049007870624040785162661846675390869574655778199715
    );

    vk.IC[10] = Pairing.G1Point(
      20541733849224961429143206745639379965689295743315696902725555739044438474934,
      8147371605643383323140174491542874253161386118051851582232829638226227080532
    );

    vk.IC[11] = Pairing.G1Point(
      12982418739688254044059979527574725259303760882174184519693972031620448565857,
      19418912174765973392432012011947991945763719217645494449085427810397934712986
    );

    vk.IC[12] = Pairing.G1Point(
      18638777959623437322395446162719893268698772986892036232365676264969023580307,
      15355980206968910297788431429241420808259434947452185415582503547636500907276
    );
  }

  function verify(uint256[] memory input, Proof memory proof)
    internal
    view
    returns (uint256)
  {
    uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
    VerifyingKey memory vk = verifyingKey();
    require(input.length + 1 == vk.IC.length, "verifier-bad-input");
    // Compute the linear combination vk_x
    Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
    for (uint256 i = 0; i < input.length; i++) {
      require(input[i] < snark_scalar_field, "verifier-gte-snark-scalar-field");
      vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
    }
    vk_x = Pairing.addition(vk_x, vk.IC[0]);
    if (
      !Pairing.pairingProd4(
        Pairing.negate(proof.A),
        proof.B,
        vk.alfa1,
        vk.beta2,
        vk_x,
        vk.gamma2,
        proof.C,
        vk.delta2
      )
    ) return 1;
    return 0;
  }

  /// @return r  bool true if proof is valid
  function verifyProof(
    uint256[2] memory a,
    uint256[2][2] memory b,
    uint256[2] memory c,
    uint256[12] memory input
  ) public view returns (bool r) {
    Proof memory proof;
    proof.A = Pairing.G1Point(a[0], a[1]);
    proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
    proof.C = Pairing.G1Point(c[0], c[1]);
    uint256[] memory inputValues = new uint256[](input.length);
    for (uint256 i = 0; i < input.length; i++) {
      inputValues[i] = input[i];
    }
    if (verify(inputValues, proof) == 0) {
      return true;
    } else {
      return false;
    }
  }
}
