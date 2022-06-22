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
contract ERC721OwnershipCheckerVerifier {
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
        vk.IC = new Pairing.G1Point[](45);
        
        vk.IC[0] = Pairing.G1Point( 
            19915619029488557051015703440041688910410410092074497289203482808482160820628,
            18945315995039948098551037215256899767496856339313023739683410771944393237194
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            10474734975593033861377315771371652306096376608638957761356024507459913886672,
            3368033732720790228176735974024384308833901805496110021550052729565041473696
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            9683509310389080431430746490306444529541063838138212166107619637987855410330,
            12170784953904971660266346991052485030054736557683425537031573915140166451505
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            10034905364308096005404034428006424439463026806194817953050520123699029590878,
            21250830607066965566865746143805156785804020066759641839391483418246210162532
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            19259968251383606909558569129718842422403137076774649369212509461377068900483,
            20606751271523624361834041090472142627626186308790005784019923045663595149219
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            18906693347912606291157141034787270006483038872651922785050856995765528938144,
            19706707017475218124189522937383970929755872031306386457963537876485368736355
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            19151632999245913856296344592121022178162631349481177076064608205940683630778,
            152764689480452971721126415204138617044906624390879271924174096054944853441
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            21542702756064562921922836539761894007534928251252087011996399699073441108445,
            12053394502815290933038156056726198610614507375145979953686798086364863596681
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            17540274002532294266658291971655096038456526998552295736977960246382618131264,
            1407178329739898817609445768609083715075899249712592269257803858616502152685
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            4370348013806432374668593759810407551428496098291774371502836854168577713015,
            1393665476916013385000735382356880235721619695518665423986576858603691838603
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            10520034635211621408677676131489412684324928836212853511163477762658445951429,
            13052694524393560094024553962032955551876812872120872448900579643852968052134
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            6483165953337370845248833781417260933866080109758964417929288456841083950689,
            20786047209717749064853642801484869338965846141596561862658055443758637410262
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            44029567269658845390307415132611679673963893597764778424894915533621225834,
            8341881857103402909799263152349039667736526264631696416289036771177034189356
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            16238427472806622194393396250540084647034488754506278338700522025286186813109,
            1880554262000977610029883462898255763235869547801425021362822975928546450841
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            5999812366699457580318086284532719395421578648500424236663525652812426019077,
            19082440014424566393423373011892322274119677006189065342028278754272038044784
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            20904526215146921038929560575070272872464400933292488264366691973736256443014,
            5182560710788980705596932389984058095085201783065198915037634731930598701438
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            10092518139697670873046690466658390704821963966783477230401547076912222042000,
            1707308900925837915254051895567172331087025013846057300859313997552881930939
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            14363061578989913846234453890650366556776736247725546939789784815708541275262,
            10920625902085102849682252000126720906638921583668872122956403122291991194804
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            13485562024481559892777788643991997696660118151974137540487131763421113009139,
            9683806186340843834032813228192012064712850181966830541628055012596067167884
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            13486875241115045408032848355999644335659186835519333596107276905454034602140,
            9755783222993159820634363137161935577113376543403814854543188493115000996490
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            14989890315790564708988986269479340918110122568341021598014729863261847032012,
            18109005820773537601726353892102627902082558015004463675037725565926042784445
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            7469500665583479519664190566268592219045915049622338645515792165214326021517,
            15736474891689122901207101313445105344032735251128733702877760392326753578081
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            10009184732908440007497537530042505747046019644208918667398259101165569562862,
            3219805863219954466020642489503233312522480895985501744967653081814261976108
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            6472214117674841831094532945140878540367514156733377361008344192786554116474,
            21001587986433391655948498163258899929078351762229880591140781925218349347506
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            10769777738492388828664875922480556908212225413443384679817725670084064538054,
            1540725822538773425251544297966559145410470733007596719547013998100277665430
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            1605122290455735000615234408944818505249958692587421043625446845822601957287,
            19650476593329067443227914048446609108343033151341339191557110479604473056692
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            14939960960283055050212223021392273036930538852569089690222230856497928077617,
            15575002987730019620668320408658011871565353480934789874839320165563230664237
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            14680668688788122750637669089876812101767037447850394914685626580941777460630,
            8710220857059441731428124542487928155501585626922202137022575226164135958584
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            325105328472567760588396406468753579372377718743944474443549400118250488429,
            1122894800019368359769910677356455302200996612827710190192990488249396441678
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            785614758644302604716094404559021505612078827727519823435436390265133286198,
            3728435686274897176946686030942450832283832177221976874014693536147192424438
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            16292066417931754797092617082230187307977895220399241040718366449307151033594,
            6522670615807119276569946598349180410410968889212538241832707000167783483249
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            2492737800167295669651274801934364901954173513821736144929684079638704915728,
            19340620566639753445843324423827640219257080494437504546076601043027910185440
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            14271939124771659484262339747396274368396258892586069224144364404264579547964,
            3486687419561995363798252247901611676512629094127071054356875251332620845542
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            10694194454034024341939088844159455157954586859253044242449326987765431391206,
            1949458884210683090657160197819156082610635150792161575058550802270116030359
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            3477193350359603990099833515292615245780521265730315761517216512140178919880,
            21865306997099384981660394792955122801080607644324891752819716532176978645076
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            8140625637018640082799970876361395400461384085411747031733633605577605350628,
            8512134376163628003203510122852869174301296846908119090777733622879425051067
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            4323665647199992891248794917230621129742601776584330652751634369155649263151,
            14658682075450119545361838480475254906850488594153537712355201779577631931992
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            8184165284110088057402439054311671386452518613117488895492372593171449608199,
            4106144108510041083196978041931619401209764952089690396697921256150162394610
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            14674045457617612974856940837359319855015236629330456219719152533608197855900,
            4887632927411980250505665933335322669951438960413621090197007101958295170123
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            1464202573434941041424134540804482773018821477198158120128648029465191127089,
            5672064010244970287640711578694167776186675177659682302278108809213486187056
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            13405788688493041146406508527053834956413819593091581839219704405248793790155,
            5630111588713060177094243420194977149241125472446261506642998793231533823929
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            9777079360041439723872007042268343325022623412303034852239365582471497737584,
            11534317935759667628516803245211229081586315131895305250600458010811938921987
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            10312692092320116107951788854285915328296835650268299431933887742113095375933,
            21488658257830932719136955579221740549053746720395420269189633814243655307083
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            8343478040369187271927554023098577692160554532970053921202154660935020259562,
            9494979579489034542116589894033524057718207156460460289051704188652694956658
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            11090851872854427356073996206908252930615558236836464983039184206675072749441,
            11295949748535616217257115764629963929942671401768276636862185812965455705562
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
