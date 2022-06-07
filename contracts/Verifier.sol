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
            6304584710396321249076850107511363604967483758830456893587629272211284087123,
            411452310660220764128832489415607124352005991677864897734186698064888544668
        );

        vk.beta2 = Pairing.G2Point(
            [15017531049361926946137687778991433645575445651371449197617507216686948053344,
             18964138011790996460520038926153058845389546277466459251745268328965103575289],
            [3501243124934085058850676287297634925117755969803617675447669673821114966303,
             21518796716133726094762446637191463509198915251709065252438065333189160948323]
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
        vk.IC = new Pairing.G1Point[](45);
        
        vk.IC[0] = Pairing.G1Point( 
            2429468715577615206011027735724818323590556169778627735195794630537189852612,
            10797614708100315641110598374900901817857268771071423043458556642603031376600
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            8010549717723402843625189182852816850421986811688324564782025902539373291148,
            10892999390596086543913272761430341890065106154807292790502425265756680319429
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            17266386105896083969388084530891128604142828639753648536304588675164184392047,
            454366754222631074862001099394448564978803855239282824666791869015818057801
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            11171907394281429583791105834904732438777788395716007786639863024634005221051,
            11921137175440181558297925761636823338339709124591898162752847210726501950228
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            17012660626434240385387268757291768542209826176624340671583597881934859462929,
            15509453365469788595661974731281299114532342422318805147313267387569097823150
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            14836642834535406305406146655543755440695389901708836872221204535901146839421,
            10901306261546588875716824597858999189743168639699515183487039720005335444427
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            20929470735572631579568068438078286930699809573112160913720235679101967101554,
            2924605359674659705771564558774501999808496116722446261660551935932119073304
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            21516236890003658514028296424058529994846745662702479882793597389764127108130,
            17318669476217256141004291829254659835791012398493190738858409326608461984481
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            6878888972030188605159104791260155517455359878427413136588366434143202908230,
            2616983359566048342542491398814356096808748582179419460281578722638781534190
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            21381428732625393061571074620032915018241423878127533587947862942869692961215,
            15684156153793626391157632086876448334708341818554265914769226242793963450840
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            11001378512777529597422910523117028172142724354061162147504854128291707654846,
            325373218096774380613034370987487954879465052002276484441982936625675771408
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            13798417264716241698970587507233231743550907563923505603193578428622723607549,
            12490050955320997822148999216696015308704563641780567334236687718774073962304
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            6521277598190970379485169211234335755690831063023102415592986187020206190717,
            7162924824723577531959109367524351335157216424016023716993043635736527383599
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            21723794224458418618459745454306768125139155711172109591020867411266747405382,
            11985534228934500912836254199235322729018693800727898021412045684453298685351
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            21644304400699155378600339206847534033511295370626499660328861002702308232766,
            3013296542476609336270667473910143570984779888805729456211562582072400540321
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            19839520284832905609372820112487999368187637881023967196066243562432317621050,
            19378625509574095506815288131976143713272835157337700127208801160877211273847
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            669090114237565265325426335633397688450657075318205675894735207299042727723,
            19722800589717144357565561546058394558333312662669763247605973012991102363385
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            16231370773258852424295094598621742626392534614972143344051510479299067275703,
            5186180302303697340496666628124228681924132963716013566045520278358422544686
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            2409935171924626834257844883065055154316400313528851663388968433581191348671,
            1376854394211250226794018088973461974594076276389788212543343285457525646684
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            13372219413678558206880845327240317739137328961161139853248662526716924239834,
            12460808896800959929226627384397551167811971811681790871302898825372461254354
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            16347077989314684019262890060851587763703160037970107533774345581503965815494,
            4247464072752621514049502976952229986478737204125185273422623211612771851557
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            20082069754584381486871189707956783943409669238343353788091175447671509485603,
            15729130298997853366866770629970204251382212852707472241834523379740342471959
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            7081125997400093814890131059525150706474560917389145844775166265302928409148,
            10745905823041806819442946811387530309147273469159981600954578384051030710480
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            7031480545568936946209562585342913901265840985404154423131365059102147111483,
            14838236787903170091491403746119640878661515716839051497523800396926195799830
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            12906126058296243963136410781052647013344205630686771974126874177390531334717,
            14540026095856647158686482866984243888961730092757512039671837047660049110481
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            20985838551424963532354511583719942664885432376139906565277223768239008324481,
            16703999507444939546897450952453768723014436700060741901885172593908099114736
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            11407271477549432579984432271167635023110233084517447588682550671244269486213,
            7898064936883130721598081667379254454564952385095575480848704294690130951969
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            4039050165044157285991526746845174371283466979275339138243056537145393952524,
            17373767334777271165025678147485498392800712443272676977847745741700797972885
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            1263863296395488275514945315211223172899365579938715813087305755543901479826,
            5403301045980299235747480504255436721414530464090995774398500785856861494532
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            3019722529249387101487024637243326641668996539627166051885107791894185551109,
            12917971529680045297549200196145220534763291590409430345012274471006785595751
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            360833243687773044107993067782544732944063622979958852445082049438110629862,
            20346536364417431594759565351272166537961358936241124867622388835979611880897
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            1230852507516457107798658069460483980623397802303746765177465221473174890587,
            9931397960915845097922194379638159933580940450967007880653214578276450053225
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            3100297425381809077419205252933675314180428777917520594254896679445843603663,
            1874821691430515784839214050907655476752947116712356771092726239876894586689
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            14971672789344682654024240804483336709124989157367835737578369106322090719442,
            7044220685240782341825776410482985908863516480960830064219722229233583541765
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            4007169643211067527912609160128702780841891402890239311087718008248272523216,
            18283716567997112496350424961263842885848304832424965529602916754566677852613
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            13919307484813670522763817033673216267967161625460851052186515639132856251671,
            20467444564119794919677212390030677292047337637069176681419281532133603606496
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            7713072580472347150639067389886534017661384432967699472943512076220130336277,
            21409913408256826619840640318194261083884004798520580657255882032630726772695
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            8510282404308064831682130765530427071094776192839451596220959018358268945974,
            9128500592746470026082762437005341184115326786455423810133074693330769444779
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            1830869351465026803847031166181831246740433120077034423655678089385894455275,
            10421421864598426383373151571303387807769684188712061567979694186219614803847
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            17122014820956981394584230671523424733601383878079840735677055625320696903675,
            6166465966171564657146146863036418002758100392251314162311405066604816357222
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            10373073753579443568201259468926242959982048084877762501594531628648918340399,
            14430944794288170763038701214995921146325855103446184982013140467122635664244
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            17329592954477465538622108751984575961146537588811008687837693037528055189952,
            15951990155471551303156453199144971431668447049494927411238049300612223769279
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            17546506579603360354159830652920441880192754673151530277940527452941583116932,
            2662849359071005884628609467009289239741169736743736685361518390360019162459
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            11669015112712043636958679689692200066163569269019002594493250590361702108756,
            9388578036720246937484083053035124069452961751247637641752284941343727606097
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            14502225637501310533602201099234886728155345795267731356068078048129764528714,
            11325116955303553324024566243320620788372222312218795438277773777924515294453
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
            uint[44] memory input
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
