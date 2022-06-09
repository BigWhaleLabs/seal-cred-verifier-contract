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
pragma solidity ^0.6.11;
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
contract Verifier {
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
            3633105060839137134065311164822380653553902504543336366499787070870417139007,
            17907691093232149817067127036469800959018545921416690841618124508632736057438
        );

        vk.beta2 = Pairing.G2Point(
            [16351496393577592809021309398952013313557040337393511458480860384805789173132,
             7856700918903503480777654685287684310952787985351204380550650260561280925970],
            [18346184816087486482188769961116863536814130013026523621289054226691129706696,
             7398120019301976171367314662048249119809671062427348996379932787785736389418]
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
        vk.IC = new Pairing.G1Point[](46);
        
        vk.IC[0] = Pairing.G1Point( 
            9118825447890956997638716552249297677740399839666980940629129790683739865161,
            14411382507784712137487680562780950358164278940887476682248408771104066543940
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            11004139261986983496750034543063094859939252778692239593255194318611892252782,
            4956930320407657302333472536407643199790707252194571775679868430482173797812
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            11560394500013646277004526322179473886559980253307533920061069521668384589851,
            20240928114042373643233227415348019705161176539971581469558240361591913033174
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            4789065985287082594372656890798933222544412190726300006696705366099483782316,
            3786102211481346742351074425156558440299447039175196803222734666122528577399
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            16767972836108944694123110458304095289947623653599864549381371559745141923541,
            20572166954857385337068732761553190153462236933889546704305658691767690079530
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            12845096892351390603311711499550607481374893878212230600577513054838859129633,
            12456692857690529939976577903847298017393429089416122541587658308132241309391
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            21027215258888012474939667792960018426031654236035493824932648805176208983899,
            18421194690466057635333892506935204549022224071138347317977028248805851768050
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            10262037467285201554095376788168028140790009924614953605602921368933133024604,
            15394551347569733593407908682670828020966567134242332359363724647026729668631
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            19364201782607705097550427626986931223289032082424664187390459247486439300419,
            3150373199238570878183221035022491031025935106133261221067290817653693175452
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            6284444406096875507852451845888268132782688620556395733486541147098222287246,
            4210966529445257095764113367299674786629217430381945370668199616484195678425
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            11314523626014681727629257941386793572641179370443393566273158000275457594965,
            3908080582863772514744980280872639345918800442029819388594768164937825670170
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            8846650436033275581909588320840240400856768376851383438136328511890471112786,
            18147470093641118430874283036358673046380699947982153507071018504155344509411
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            8374771282542501634837004838067554614325715447571195850797241964599891388624,
            825292185747188799771257863909548218549888374938023760038832457655132643708
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            17093174155445985271543367341431228546206871033429017954786822070483297084980,
            19441558674865392235858089950058429821890800526939533280491323997082716496228
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            16130372227924841994040093554557770378299602490586576069893603193222957322459,
            11359529222949742354295614589087797015765159656277654035265281528471711815554
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            15548950245214765443323236687177905572004361924213665003510785728996125717467,
            14235654291369271696739670371777289273476768602502234116235246099441876829500
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            6802518579387951335693256701852199173601466415215575451926587298160637134121,
            3056287622757605559602999227936718608937236964605321655976341537162601878488
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            18099491029173768620207752402047178477031097942781021559284289299186646305883,
            1177738090178309071510514782139609150962849210955183497126693922319884957968
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            17519447497023885719314811256594811070411135701767849824545096186221508695603,
            10506988752200116731420869150144489047616333468036193119734507712041647536095
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            20394464884469388222047650952834154173801017983583382861912874521111810898582,
            20425360721894157156242284022816122407481948486863774114150632734832535177288
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            4833255350002539398482410548972033279931321843706467908105357916823795177206,
            15985761449290424672118516287289824487145700981765292098769376758152275752554
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            10016544194151214348995273034598751060360662939623257592386181018967338267116,
            16465559449052574082387586241943626745813950948663673791735610911922510124115
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            15924010367340353618630194582579613100351853911445810083648670345525389301220,
            12088788329494029409374325211114053021978225205139764878811544362678906513704
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            11755435342234173433205028949160349566796636986286969591546013503028837152027,
            15661849059592228167141970687713792432817776270340553738413942273046062390445
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            16242342604210855975314488725761243361895667602649257066063731029281241903043,
            6475456056490275583712513922329212766433461407062578679742020446739371889657
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            15173071665261335888040392023316156387006775887076195306941187106370880025979,
            18641372111209419062755185625162233385768041942742809839221806960855941765592
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            10405782854922973209518436612982434752736841297145902567270439523266495867546,
            6670468316676432950647127220755520536192992676631910103924714953724373287023
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            16388929176590759141502666730043676093158438404864104137148286097455476047150,
            995456293631496409613251901788130571853000046250999331368699386041254717478
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            3310572780003209582053973024043737228744012936891639137152991986494999222287,
            5684893065193205035212394379849926944957672631500570434616918722520270008288
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            8663170861411084894070359001728076832981966812524526073815435034735638646566,
            18313652565350803480485714638747523955555929042549519743951076245233227794557
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            14037010372910234192323341163940393654547956551313065611093503252796800729174,
            5774291143938695693128274860271764496819154575850915594066078614062276824439
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            15266984859557735151733413358294588077237022413717980032114720490831619195401,
            9155940198779602189331570674093420627568110431805913311263683690753253412678
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            12499418827813403477865316585334768033673184858048343582228799349892480082184,
            7296377904360852925161333682382595532572576809062890994635725242998460188653
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            7955559445118090387439653310865082094078617224199199876888685406482292941661,
            7332324035280045379797485727588640754818381781508113590706719646513920255272
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            2488501174642572160327301845854314115034370877827972065536477597981349474018,
            15976818090326345805180558337240531350430897995177375690903363504243447034627
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            14925700797534838845698330330215626792806230963221690342196322682732837113069,
            15923332096306437270702816487325806759366889385492944896032636497432011959554
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            9260926138079248934980454758482782545225282918984986179598675520091991188099,
            20101443480624383667388546373623678832458523070582116475873311569842140174599
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            21228151703534947539555766890768705289870333831492717756206127757690734723715,
            4840751358447508719142378735186902727346232350188240573539861442736829172589
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            18263831105864037770495063412063003923915077640699777853843306356463151784571,
            19960723996191404668399362806042151562291169953241796531531740807469225788435
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            7742577248290478279826547306681998589999967008247638464455604966968875926185,
            8367059678195511828993480062730809305693868512005435717451079644650542282911
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            18921767343277884977895329593090716965700849065899902334861341481088310050303,
            7320371225576480802752803564859168994640294800032854547574157266409806975067
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            18206277618208712981417017571463461074007972238683408643654973367162264134430,
            15806478386126693621064130498245217182246205832055428787558885401945595241943
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            14064477176664859168474051828029798856433737268643436819778196472325462277389,
            3034768987890566570023747399871237161941801243209383545801373864619209456835
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            13469956774685030075458825521166393996737908066863417104060952506168590454471,
            18682546415014711416804373705818785514291262482197116250771198193989273764320
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            11730346610883303809403296780588197194441706833261357205567705493954142988695,
            13570670874768823954015899205211429592709989488069936611512934888153845033146
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            20582775170734444957460201841388569212398281710622351246747373694486836310923,
            5303410044024776501332432823952580649534639172870534693714890684487659038268
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
            uint[45] memory input
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
