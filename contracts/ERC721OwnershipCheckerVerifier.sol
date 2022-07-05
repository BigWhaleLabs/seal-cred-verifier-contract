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
            11861570082698693863175976566931510457749136111402786071572398243629795416890,
            9289376729027761921490010900547014694345124973307822561411190157749505130355
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            21452391009270288209200766288667896019333699158346286518669416740885285199070,
            1949438663140645378485880604842323705879525182253029952926880321177749972819
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            20397630373533954051662403025637322161251216069788958049264763855833839785589,
            14198152855392779572980898922333476286381176838020824558420130338693747593513
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            6024799665532415827362686233836590396603541089013542123345686790649302616397,
            15547196925344567695168904615157286728749700139806043323857848871648313434709
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            176233931768553290710027053899264144876804847586858416086541983943800008997,
            13863300584140073955671982140082231621777076887324235174563372264447388015544
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            2675429486867134944725009183355172341788769893087652670214605498394685233150,
            14264309032467776964698941368913991304727634020005537730812964986054708912331
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            2491645804434840347622252096005097944958035253356677926149519802039961467352,
            5654170275497446267523304228272122089518312116681577342367596939493413455745
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            16750593722916644433256634071175563958261189610536226136780755476615642637399,
            1863243564318306950362579377060417872147492725814825901207038911452221076608
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            6718456532402530128906074089140414778068207429795866367207383810461658025134,
            450980031792871005425930025667727775499558760918570585837190059874969775134
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            15281360539590993877150839404220113880805494785476960110340027956723783184420,
            4010418539864770181950921071690841985255729088490382500569967058660628240896
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            18757426502733784986431150385017044499398919249189769623823178343728385242561,
            14545712599484711445226806060812585041765588953529409261077799433810427620651
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            12548996054175518581612331872100297341422620393677143428324357754031028990069,
            17613738132254221215987240043491581661156363151868666726144501347903022842815
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            4674853792980050961468257969282793291474407000513451468828860385740567915472,
            20182279291916305165396043859359050466960668976021210695011384207449131732526
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            5819274382100335781416190338061702362256490574342604520617793261406280328099,
            11414327496156457952474414842049645005835845522440559620101510652266934197628
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            16225716977255082646649063336256137302402632151675458531042423830299437190858,
            7257522633634709765765934506086831417206960598147467308952226632792115204616
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            20077829609523461386999137762197153261153114774968653818024571980315854351259,
            2772047812796856611527770846446224241735612421485993245682684969877030097973
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            2959033380422941222589204512431141354569726893465281007285542811899808124692,
            16510373233720945546087227249689887128717621488791130203093726748452200313313
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            13048466770606335978832195809189368483670851555100512922219768791780619916316,
            2623658529204633682763554420873735234157331592145125253471479099586301237517
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            11064805206695750416855881662840898909415341827506172240114561593121650839650,
            16671159061601522792584558407335650610040972168606175578278182839648027566106
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            17172325843405900477332211060748285649609603368256800359360804636102466679822,
            731478972734468782528712344083021536330181926173823672779569588523065475243
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            4429009661827912569590019699484225110611462462271392000325139875369325969173,
            3526747488615348814486178791417171973426640448712769619502773887966752650679
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            8458303066032243788002489990896534775040738965199386118299602414528257093923,
            10434300636914394888005426647367121078715414441534269482489859756800835619255
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            4738926287551105080308380408859689000385285226766880431782294393436636042413,
            7629799751060186503038838159569088559036306432078815695410456383354166724841
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            20886807826986284175145850067614759608748723817007338966137887495152201905868,
            6539186801775023658637375853772314106800210179834261826259019501488637485947
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            12585683946001351828768222331934264529383812085841659195603807898511518076103,
            3366764636545193130726471363434694104539061347700499641386324086265348332081
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            10332036078432076060222692505292497471488027409469417760291321939631030107225,
            8996461850488719382007977203460965145928076816723730851568863892227053530373
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            21733123676616672661668039731375637168142433832384236361112561419051246255796,
            19557611779486663812379148639307079529202323090448023277110236157156749009130
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            10744606123862200602178026984029758849882502050351508348738858590984780751392,
            21161348743943633787045004524854437387850594205304208875503388423080146198699
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            7814449201847266363645485256288663155886009878817365880071377722272402057539,
            10889122301848481482576542549659968427208992519509448825197533155036149375930
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            1559414139603191879943269635055615391584610948638770791837981004685900893512,
            20862027525836922767776405627759114702394968088515785644999283854478470856054
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            16007470791986709253934488798171441721246848525267489402340219776374034461232,
            14911368196466997669209335743025232860831284269060545824585134815530757119392
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            13141434710316274966973698807752856435205263019837864056328532422881933446233,
            18316478146299974444900683342974309684423729758587025432979130561272548938169
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            20424145998203049741708771723632721647109323339724803214987889417242480903683,
            12553203123445932589830596838996402367011950521627930576801904754193235105420
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            10402926716519158226850337750997271816383489000889636172218348402791738264081,
            780096403037915117512305838798796847212011730575150847100596309045090732176
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            1318862143253463290336719814057807623813795192687955934702944104843407791442,
            18552046920259851973815658576030653114520497842771165295403347615440668078841
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            19803537359979654147106780343648531680620298707843658214871006919163826016345,
            5259639638952120869125711154077087349362673799946875855468241689261127798294
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            12755198674738398176921238501471329146730049062270921333260341936560858346902,
            3919038456549121607677908676809807001017787200044813688487416936405368696651
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            260102390938140517289363195797459896704684724822811539136146067563846316943,
            2616114075727668460425782596447597112334569991668461839331898513744919373849
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            19406315060498337220906900700507724867716772141408463084911574422050131253525,
            2459799897424013841201154475918787386302834696662425409249783602138552924397
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            4734671378974511156440997564064104999539953448067523399790953571368635649892,
            7844842709772637297651271869002841926070598956959846662879509766196320367358
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            10697045218627484345046475201784977427730452351554530658087736202734652883378,
            12773549900555433243330744359374610084955906423258545929538506675930257624862
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            15522713448242432815824391032336828840375967404131200101386303726220994275187,
            6108253510344130660119455314816818027410892100878493615344579008092044764125
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            21868849685758812132768872194633164902871973886160510491116349310702854194114,
            14144829329584031515253987752134648578416116540628164135768510159297854989522
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            2737694696525253822776908197002826717574969819622093482187926756228831276048,
            14220505158284932715458658030083088884226826716113700834178686954385521450926
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            19404398689608022852902294747738557808979133229955654366806853176629069428572,
            8467962289032086767476650244574695052237224658011971222883654654589181682371
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
