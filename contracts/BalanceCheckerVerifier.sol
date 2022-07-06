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
pragma solidity ^0.8.14;
library Pairing {
    struct G1Point {
        uint X;
        uint Y;
    }
    // Encoding of field elements is: X[0] * z + X[1]
    struct G2Point {
        uint[2] X;
        uint[2] Y;
    }
    /// @return the generator of G1
    function P1() internal pure returns (G1Point memory) {
        return G1Point(1, 2);
    }
    /// @return the generator of G2
    function P2() internal pure returns (G2Point memory) {
        // Original code point
        return G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
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
        uint q = 21888242871839275222246405745257275088696311157297823662689037894645226208583;
        if (p.X == 0 && p.Y == 0)
            return G1Point(0, 0);
        return G1Point(p.X, q - (p.Y % q));
    }
    /// @return r the sum of two points of G1
    function addition(G1Point memory p1, G1Point memory p2) internal view returns (G1Point memory r) {
        uint[4] memory input;
        input[0] = p1.X;
        input[1] = p1.Y;
        input[2] = p2.X;
        input[3] = p2.Y;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 6, input, 0xc0, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-add-failed");
    }
    /// @return r the product of a point on G1 and a scalar, i.e.
    /// p == p.scalar_mul(1) and p.addition(p) == p.scalar_mul(2) for all points p.
    function scalar_mul(G1Point memory p, uint s) internal view returns (G1Point memory r) {
        uint[3] memory input;
        input[0] = p.X;
        input[1] = p.Y;
        input[2] = s;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 7, input, 0x80, r, 0x60)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require (success,"pairing-mul-failed");
    }
    /// @return the result of computing the pairing check
    /// e(p1[0], p2[0]) *  .... * e(p1[n], p2[n]) == 1
    /// For example pairing([P1(), P1().negate()], [P2(), P2()]) should
    /// return true.
    function pairing(G1Point[] memory p1, G2Point[] memory p2) internal view returns (bool) {
        require(p1.length == p2.length,"pairing-lengths-failed");
        uint elements = p1.length;
        uint inputSize = elements * 6;
        uint[] memory input = new uint[](inputSize);
        for (uint i = 0; i < elements; i++)
        {
            input[i * 6 + 0] = p1[i].X;
            input[i * 6 + 1] = p1[i].Y;
            input[i * 6 + 2] = p2[i].X[0];
            input[i * 6 + 3] = p2[i].X[1];
            input[i * 6 + 4] = p2[i].Y[0];
            input[i * 6 + 5] = p2[i].Y[1];
        }
        uint[1] memory out;
        bool success;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := staticcall(sub(gas(), 2000), 8, add(input, 0x20), mul(inputSize, 0x20), out, 0x20)
            // Use "invalid" to make gas estimation work
            switch success case 0 { invalid() }
        }
        require(success,"pairing-opcode-failed");
        return out[0] != 0;
    }
    /// Convenience method for a pairing check for two pairs.
    function pairingProd2(G1Point memory a1, G2Point memory a2, G1Point memory b1, G2Point memory b2) internal view returns (bool) {
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2
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
            G1Point memory a1, G2Point memory a2,
            G1Point memory b1, G2Point memory b2,
            G1Point memory c1, G2Point memory c2,
            G1Point memory d1, G2Point memory d2
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
contract BalanceCheckerVerifier {
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
            [4252822878758300859123897981450591353533073413197771768651442665752259397132,
             6375614351688725206403948262868962793625744043794305715222011528459656738731],
            [21847035105528745403288232691147584728191162732299865338377159692350059136679,
             10505242626370262277552901082094356697409835680220590971873171140371331206856]
        );
        vk.gamma2 = Pairing.G2Point(
            [11559732032986387107991004021392285783925812861821192530917403151452391805634,
             10857046999023057135944570762232829481370756359578518086990519993285655852781],
            [4082367875863433681332203403145435568316851327593401208105741076214120093531,
             8495653923123431417604973247489272438418190587263600148770280649306958101930]
        );
        vk.delta2 = Pairing.G2Point(
            [12599857379517512478445603412764121041984228075771497593287716170335433683702,
             7912208710313447447762395792098481825752520616755888860068004689933335666613],
            [11502426145685875357967720478366491326865907869902181704031346886834786027007,
             21679208693936337484429571887537508926366191105267550375038502782696042114705]
        );
        vk.IC = new Pairing.G1Point[](47);
        
        vk.IC[0] = Pairing.G1Point( 
            1346824489240508156798606293604735526241534166135648050535812573055469282553,
            5470027682950386905468860575655214276777949560562880340122326497444698170568
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            10287121210767766012394107786925258052773362564408114336827544825255306677118,
            4431619325994196537984837021395202104045414611811716189739481630777905192918
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            6286566187144301223803825280780060536712579440915467626175805662863966160807,
            10769831909315725214744708784689007149587078681914669001465412163769973931610
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            17279127906842925989728881894705178969907866991871912488742370023141597735323,
            17737297644850398658112962735022308576023970446844092844655781065051507261794
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            7323428985743605498248884516026338987472241677196068518133067678629103442161,
            6117546004996198758243137539232527776391891073140718490930236968407293686411
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            20685487830999869160399038590481983567461729743603059525711840638122403680919,
            15258555716928192550079512949687547461758539414007007719708189677886435376291
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            13575302178152422228275147240196208783960030585402693565461115315145502613694,
            20257266103094422809322123016532240205826552069637842490292825338458090176333
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            21170231844206637578783890655306760488681903688482211701939280770141192824462,
            13001115360182050710657059574274029463198973035392893342440833084951001755083
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            16882743153323852473958462846626785178767247734767136923146075961689206700136,
            21548268322055098411118070468289906679313739453327950473583261341163848943359
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            15607920851957492866564162189301375596410947891252930690353938152641592806286,
            6150509623885963734313278520020889209780211134858709228470692567584788543550
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            9318965675170860624881582964306513399944209696400842292742483631776075860513,
            12388257376290547670419055932243654805398728872855923078207220125586605447629
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            11531742255055238722295215299519260976265490281027759123237187697399157095551,
            18100051918257755852445434518580668296840991192390068589363254317317975168785
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            19138821795609955945930812709710523878335955405064720836873725329695588549837,
            11492440432439680677866197764593280801800962097182221698784972469100595492272
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            15265121836574261690325068352240062064423541258358474959308599757861475435066,
            4024633321460427428278035789675493568460351335811882164488401164667959830824
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            17342225043228578480203009768663499993366437298696891900398936662933835049716,
            2343220066758483088292320803602512383388467501225047031863925529084115093693
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            2292233353207625656726198706601265132805530040879484480109583243331148312170,
            5391854537212724229635369500884910550484318133666516250348057489363739598669
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            12299340310705973131345431767878324505695006834801222373278211620488046213349,
            9019416465325056101555420884092079500892699288119907950568861619625414209467
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            924880131796364017905226730203043131637465632902819271915064342136293877879,
            4366783711124959883883657757664770271585862394064279022952965475885343885976
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            9427625978295125035694046097477222337176593617574093671431996274342667460210,
            17340411012015695450343765682949469184826963527010243480016959657158512424394
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            7193170425261790678994479322564643344730527782696241288454557281229899833373,
            5533816953517563336331293453448967557086425958549806150720228732458457067905
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            19633299125429367608493823483961465787631245918082175284725603255381163342180,
            2542571619163553294814194281017173857695105205896865160348282312587405963794
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            8703891072342759658619982044154499948000542439178907981093322761409124549501,
            9636273992818439856909616038508350427645690964786967547454224800892733316763
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            6260288570834070559220755285899050758575954727496878904692908797885166340739,
            20988800333153438642569119235277794110788022503501662275468227033073635245300
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            16256147074842988556945832541012334036233262952179230515560977594589628368875,
            19045067599572700446202149130578757842393683173502924036581552473500511790788
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            20574475628402580771597211284455492541347401867567826346072318958328906420604,
            6216059054800222069343085579642504426942305267850588684368280574796136888716
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            10108170796576034266549422064374305729110399281100972355149218149803671616873,
            20473995301502763222941236044470451105550215578886267611165987983275589855459
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            9949506776615187239188800653109539673457117662603753954897003602484090542835,
            6348454298699953911327049902131247041473212635448446515750784711452405683498
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            20248826355410321816344868402133051129791272302741643997229648069348458075268,
            8093315290667515424197863577391849156232123620220510869876513427205711177780
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            19031591847548523696356436636549978914301788205088552843976988265002558393854,
            14807155586895525504284534002098634930367985072812808862139074699589442519233
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            10503036258370745680928923160784225998590902444261190686398483911739406322589,
            8956948307085628011563063982010052866859161667364968916627245598921337447469
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            11323401829205628068217281691636694051666998621635911018834544886519009058565,
            9655035633759549398315944104646542167072424879051589246778931229367218838889
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            8007166987329127846564679802674525129044295559537759042462991142838997153862,
            15515038026283589846993745859257872268536950609531654389914854463137718273481
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            951175117897767039120733786719947922937382552127583228933422649505436098970,
            6098557263195015705541227849988406930312481400396031086762679695548865940034
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            6162443932596487382905063225848929574740866921382177019998154846445795241978,
            21135451515934423131730673865534451196956950938366737656740223737893920165601
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            11457592864401049006954022288452789069562127868928759165012361897011532886725,
            6021691704518366463403466024696443073563630015155702517600083888120001635074
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            14233097952363930031857364235499479008554323530150457669667138203243876763454,
            7275152609192627998868334274215205574409876251394950270672933708191602999297
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            13276985974490007207442213374041789858142278801498977644308688971266194312202,
            15665262268663532765489296218165178954357133008213698462495803940519935545968
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            479327075184996926813268196102390278621632942810738944160823488336868414796,
            7511686947775588239570509498475956565142211073115947702382826557659075983453
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            15891467211082660749759846627468835066250798387222634244636616243913919392866,
            18190819951136216727555742760975499655764688376279474579548479180523312766955
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            5474510417200286363891107230628261290498422736526868921399850782829054527220,
            7101906153285735711481428050128834078550860979133327214869597099425143748388
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            6649258430109280517881050250071999365845079883154387092075031828922226057508,
            16966288995198555060301211300115094938658912785720569713534008476259512820319
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            8782891364393333459107091191051081934264911191112830912427891999278067950263,
            21141742541588850924569949485994022935356962683833988579449756184754797778095
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            10310795752801525529481420910849823960186206681114465461906658010234390230510,
            11431081052490735961243836701597805264597367023860388001398029266897064655205
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            19166459413419171004715053273270622722558583113722200330529752829826521450673,
            1716962919579113382796001274694685629609627835980744442658087127375520553804
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            4272686380777863281650229187733232522090015425251680949881062233511743998900,
            14116107935165922257067658425921137306306899520640531231479345769948483897828
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            17898511474038333938127978438079936475595991341040954690157794842953225611512,
            21521276799889797412716925300722903611763073646573544618268332640473044227944
        );                                      
        
        vk.IC[46] = Pairing.G1Point( 
            9742249681582541118726373098306131304118201401609853915994325308820963756937,
            18802668639004776520975165020674162888852829654733560555405031770613180370990
        );                                      
        
    }
    function verify(uint[] memory input, Proof memory proof) internal view returns (uint) {
        uint256 snark_scalar_field = 21888242871839275222246405745257275088548364400416034343698204186575808495617;
        VerifyingKey memory vk = verifyingKey();
        require(input.length + 1 == vk.IC.length,"verifier-bad-input");
        // Compute the linear combination vk_x
        Pairing.G1Point memory vk_x = Pairing.G1Point(0, 0);
        for (uint i = 0; i < input.length; i++) {
            require(input[i] < snark_scalar_field,"verifier-gte-snark-scalar-field");
            vk_x = Pairing.addition(vk_x, Pairing.scalar_mul(vk.IC[i + 1], input[i]));
        }
        vk_x = Pairing.addition(vk_x, vk.IC[0]);
        if (!Pairing.pairingProd4(
            Pairing.negate(proof.A), proof.B,
            vk.alfa1, vk.beta2,
            vk_x, vk.gamma2,
            proof.C, vk.delta2
        )) return 1;
        return 0;
    }
    /// @return r  bool true if proof is valid
    function verifyProof(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[46] memory input
        ) public view returns (bool r) {
        Proof memory proof;
        proof.A = Pairing.G1Point(a[0], a[1]);
        proof.B = Pairing.G2Point([b[0][0], b[0][1]], [b[1][0], b[1][1]]);
        proof.C = Pairing.G1Point(c[0], c[1]);
        uint[] memory inputValues = new uint[](input.length);
        for(uint i = 0; i < input.length; i++){
            inputValues[i] = input[i];
        }
        if (verify(inputValues, proof) == 0) {
            return true;
        } else {
            return false;
        }
    }
}
