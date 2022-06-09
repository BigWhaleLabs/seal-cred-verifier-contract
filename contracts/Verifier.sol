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
            18617737947706429311532674278038588319616691247339380608237822471555850085824,
            6208179610155433755486930228200117016809336710388515043212704631564990086523
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            16855711253683596410181203092015595895002726279443940234004548971629409409717,
            176900397786576152898026544014983992068356124208354540404360710446567464073
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            19245452498395079369456237299459400118414894113350149088006108861018995359705,
            359088321013552223009272160766024442893585996348545968740276239107835948059
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            13019330730489938787832238943723409671803363245631532035479661857082120957119,
            1299773436753761486785113587924221764386819344608266765311082362965164608073
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            19636241760579558789696129250993942030513834419141305008404668070295746576019,
            18751724277894465141527045004913617371973821402257166780159305262820915874223
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            10288884490075172632385744929850548695534907686633470543601529472612287117706,
            18265958660260717791701972966456186829478424460444600558579701636001851837543
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            20060528333622678091299848901917206147885692331860589937858828258766542640147,
            4313310362357974656945307001844825988419814502103926208730557056700252906281
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            18670893868128331408965530197163785107584525282583698078498582281774223288487,
            5659725340149479353158005609636442251398716606231507099984528708043723356503
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            17097130211107857758993414371066487603644644467547037868248292557701220481105,
            16604239389578249900554983779337566268810962677937992963514379656902838693119
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            7387724740506314646545083478862162107878062699574830271423398625655362472230,
            4385389690491549342310199250930238607303837708582560387835922298119221614309
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            3133977511930646588542072703029741236254102664835637836529785385930501377602,
            2034723219023855821179468475907728955578389342184424676150129341892297528834
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            19748634353692894835608349599377970898792413383708303263756909856602516954301,
            9047236762273580991247587792755281950987983490512159339209297755882006180513
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            7566017457330951514070353185522487314078309487471885202183934465771336069063,
            13149285486430963313820389236846388150825639079688406182643592844576718354024
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            21418563949614640415246608191761865455665257868663130927789532121852044866667,
            6371882682557728653633649380879503726609074228482378921094296819762023050683
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            5884091531317444682852301251165092598272192062089675847597943549367621745866,
            16833125314113328496670257257197248773566457128127022078331317669643881835404
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            17392937585493382715813599843948498898311002326281396617649535492663191921637,
            16439456365151186290981429182137353234774158639757384611846998130302236192791
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            17007422101790231294833236220353616949602333909988190663736193348398845800197,
            11617677333680324448920651631685840133338433087120366894277109931379184994017
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            4109748499940308593844986477257883824373578665754533192252049682597433348695,
            13785728487619479801075411881220415555971304996916976184795823160869618054540
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            11144784268385540821841963547995584292022668038599814141592861173966283081243,
            19771351963886718602918058069425777730131550502716628952907085953736609577885
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            14542764895616207995521160516506062359934594790335623732876132654544670044694,
            2754470566783840505282853986539271569518941427000239357289498452290872340827
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            10869074908327837009392321455603902034782233773291153735116354197826399824205,
            18054664068372145084010737230803960911393567704949211179547939683727122919294
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            14475058299159687030731123272417889287869467696276469829999170261375341857577,
            12033370268745682070009145972206093886381114439635943790998590805517694771221
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            2228421534814918591986901410919663211586845265358202637593423793561458752451,
            6615645523198928710904686591507513617089131772196364962010412141269909017577
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            9132689329136891763841340012211402142173965725744386101341208012809313789143,
            11787082266536068891171190802273882519748552269480559005711256475717604214798
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            18327399203020868952020185887387827833620515925901844177556991409528296815710,
            3400322734197986087408179941686104087022835971549084382988784588811967102661
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            5976260626691393463386606249914496027268714701539526828239654811274360162895,
            20436373286087782783121552554843217774058624932369134014483154717553664377850
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            19529673427891215583385740233245073947422138089610458990918409592964746483024,
            16437924745821908297554683385267180062775812082534405805497526886423325619937
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            14726485417784794319169103345129359797349761379629207705602896415928894867641,
            153983293232504533873983213422058944537868978717242273269398001059939126116
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            3066506430285410277176467825288580449714641044577186839544063412099776902893,
            14719814291826269173986355985215507597679806856135786933649148483061515041572
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            16260259475131820918402126965966853760916999656500953663712975219260477449749,
            5836914724750498783704959282690650006718754730578500376884405451145891538968
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            2327204423057055513297954229689099768452454059180299077615464005749483717358,
            3045905996674114286198296416075741156217445706469429176850951665455369046883
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            17631329403549009875910257821958790922055717740925743033493664971765272659087,
            5109764521835569943151684828331740371786476818600455676008593525629857711875
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            11478493374811275833695478531735445126518246858838951929075069876313496229391,
            20364200797514619586875003941666209819643400845155829932005490435419203572287
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            21585334112937817960374723555597867535128812132772105972379742343783854164706,
            16080428556354896097987937893199192909069431919672487442956627957266513551195
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            14199352435292354538296003335665948385641376110515780879751918519388475933950,
            5713368410912423147026396113224498531556008826162284216412922063341558309053
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            2692947119494197098225402207341548218966339440305425570998319059222412944340,
            18303336075781268157027278245260514524134835665363810761908053031779023189751
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            6792899292963813622969282351285429851849723790581278069863228832195744261041,
            13979416994305447789627942447459704489510637471180403126046507818779755247710
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            19649844450448666915965328332635542395493057084403364972638620116289488344912,
            6366282124872918672555361593511789912318745360784150051896402847368908033462
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            10761008146758266989020845485172138542431813638782109783474771507221163566725,
            12546420503504464035060135269787238962095289936677911066034644829931743065552
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            21701225033195693537361669648252103293841272640443668151722391205145311825906,
            272602615539990896800940997757653489421895848395310386061790553618008726413
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            18290733603048427225110362365045469168307330173899964907873352834490762043440,
            20830683301637817906867801432373532042730756696329346828656581009041276763216
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            2030958704496918308320499621802976680411889870127360031072345423901917606172,
            13692607095092043737589173166364993565841433904956052870087542096746945815452
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            21287487698470754572880285270807993375943567677349322295760693981036463699146,
            17883372531916985643248241813977729361334984550485130705743790420125749410669
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            2400372923174289393641388841484606168271041306903150890051085054912336721889,
            18063310932351189594852979350380197331587466690249768141778462076835300215290
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
