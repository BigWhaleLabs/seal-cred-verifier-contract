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
        vk.IC = new Pairing.G1Point[](44);
        
        vk.IC[0] = Pairing.G1Point( 
            15393866901492630444712668330929353676562521649242164403493062096429580651019,
            11997407879652038523527205819599565315231963574442787545852288618294572768837
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            21123542380058042762975051088890616477525563036244315022716162765131596235970,
            9977480215942582546082238341123518039608078175029762640515052599208133229855
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            8336069199821433338336359904377755704528081774418479956897594883512203653798,
            7966332240177564908938129835472919636729178326540650481825396728105227374599
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            21852518925562385342989776581636283662155277062402148157376547737520033351470,
            21793772605254969840676773126871723123847945604882910383398906869950443143558
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            21756725127030301638625247723118618875530514765213844624301809770940011563088,
            5805957682831699724602385460617297852857009924405361397793408483407082944144
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            8358744898681391333182520977247130380116242630560384352954522670591253527242,
            3795699298942516918359160302872332004080846596636134953703751881628582557189
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            7812555989783283470427439520107196666382568832213218097416690092520830477959,
            15233809702749538987023449567138857986402586024764668761354093902583876553021
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            15533896212541319049122702101674338534648460239320428506225771396712233178664,
            14305695305533942132543318727835606626335846882933511713478353056403762912336
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            1093292592436685281462697508600193977968037845578060195796831679594585148024,
            17058714153811839840340825869248810210433360020475847514091862505403324562737
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            5121024445904178383491434723741067737890500358564127151653516672893270092687,
            11635484239620626727644175136856764869111282084585615700387954639803936609495
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            7235311009658179777281951241885046117307772395556444157724442459086756585934,
            17774328889857248815513824260869104851086851192070362165848946139743559301365
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            6949313934260213934712391941701667895079958333412526775174785202746091086367,
            2410078829523067037224867153589165755451912107900293342717282469049374104518
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            15963358956529948669272772989682591367286354817710519005628642581308161845832,
            669128515222989093332012351780313682006036414544167932290527537875594475160
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            5361653279470909686610946938442652076273083657171068285820181097274193211783,
            20104626413437059440641770182480276530190818834754923382958157025227902020637
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            19270823337574644246886027554392008460433684463925470917104332003013818750005,
            20996538808773659565607783400196984508421407436538021514204142579063676069967
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            10748649817353601589999425201220016276956642168448627566707767614994852942640,
            19006909563655356108454289773819314950520492891092845118026106507390574438844
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            13142451021348636201616206066326567383795812237124958054310841299233512446910,
            4909478426590993266319061958093819868945310256082180719810402558423584580699
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            3525203787512520975615806265357763159711275846640216702793008258744678161696,
            17875546170400656041470365969633925245077354245279202089975357068334973437095
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            8628448376891858665282447753158165845427948197563494650867446199386506815445,
            7611959943323639209378428861813223201483017300896055434983909093603065493218
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            11222240330032468883774963754709561112455428600482520684622229958724401854494,
            21616346598366735307733096463607616764616927224077749941358329317846385142656
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            13346814679851754749657846199371994636539123229526432795145954520593837011028,
            11059361799003042575259210924408959854669191026509392084893083130755074644290
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            1404051309701327089363007929858261628702241209745456426156229353864069878782,
            14014377910247531020860528420683085089379163289653074144759742646416663273619
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            9760460467401069729248745655209642095842156232555075791655274511667720835915,
            12272207904977535812685120781074719646952966775628902388990763711129267240759
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            5502179862114120556751439134489155713363194357812301861947568144012037554611,
            9878923232581671639741414875508490856253594258245691840012913394756326023682
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            2386312940360424635889598090842309110292793009877268817019165735713288183191,
            286539722896405745214984590979455984090184139085293461049953335604854116888
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            16812103698921197639220294141566198309075627173816779159109960405883531233777,
            21645697849510961438421876362268846826441212481432425365139494509828656430445
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            4249866237216716576623269034682832993609065779456780786681797871510589493638,
            10169463574479067927732488679373307796489299882240650623938946831250831503884
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            12344992978060039999092853801929808511306725911085242063983312466813208684232,
            3105155661852711658288214330288821134808562905691329968759140023228552842257
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            19723842347774767439989696764397058508913187180006358648094396691884718767924,
            1508342084518811280452246677857694556740152648996513539395470512649125399253
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            9625120281135300455858874632499317504256143752319550888737277067836484470709,
            4738215991706730059731478725811824715224161597959546715978762920999868639861
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            20832363465043454875523009085300650429009383198204415474072563886742820215431,
            14991274682519830109051470300344920342161661602718124730252812569121668110898
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            17796954369090020202173805506463599407790656703947042322537032895958000902459,
            6130390806196865097324722391985191567340616122324580668022634460229668646706
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            9859344881054713818744541309627523707317641051601860016853901212271437202238,
            4306840316069540769902801168620756705023976915752366171994113926276937780517
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            2372175809171121295611269598801576507519497987812423437274588908700006353868,
            20897874000842227070604490212229829258145182044572466782053568397931809045445
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            48385476201311296284209807291542410579218802142092061611594571858342523565,
            1084528819515458748343608522820276399544839610894638650386147952913672857426
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            10065475579859365408483704299856480857965613780328627561475464840090640577309,
            345825346062565354310662415028136136867956294128006608078994866933232937027
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            13272494580614687300116693242825640893713401938283069896140736027625437767432,
            17203183319935967248442056551538249845542868873925459597112475474998799886852
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            16226730064032109992513289197791945787305148022928082024677631057464516024181,
            655158648648778662383226407102750359087498189995671044986180763644937246092
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            16772318979035028577476073137076615204151695038131307319303045624736698914271,
            4074615977008444259892806293714765150425606077993272055972534862619108771279
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            13593305439309083275724022464785921293116316877706754115808197904599316007248,
            1634298202958535288231466248614196374122674988827563327497380018842225871142
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            6926334154992952431919014150005776924992293781449481274930223567878347929760,
            5393644205547778045995949385117780579417599883421062372543004956165892025262
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            16477395286940314117250496291947275085238278897881971358676272828835992005683,
            21147363747100166637709483508533181847915440255901686920016323993892030812376
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            15835406810117120785804599477032228086642765894159202367332594793298694964269,
            21261138012224130271944348295353445086847630816205979178836464879364810499995
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            3266402484435937488398643493293605818482895682864974116271281662586655858270,
            21270330692166587786007808604748911020336703276178017892942111360596680845434
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
            uint[43] memory input
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
