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
            7505534216016153398182308086892779663006976681908132567679582455112660490003,
            12962679757309048919939860958595650333602401454905710529459492267730432562350
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            52723787224877369041040508048132059748157878983547643220734838744178479302,
            21320900455224184978641488200261288953092987112530464527051867702436072867908
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            18546701156489662410996880472274611667895490438285267512621342599281383332894,
            20634838561902515077367351890456819256425065503446153041601775300337739554123
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            4243790141138746052014241988057497865748598578030273830393110836825571066742,
            6605922762906170766594215419655574137631924877793846064680042956088085464270
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            6110396640861622971029518056442294822554437072704127823963902814082587760795,
            7262578909638971119856368013344092597866180754729750212916668882654036424855
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            4266292279840510988430781003327489290138404012176960712984978660765335585198,
            4816641847738327545558131533198167284991305054227143593867765167633507435770
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            3234603008526086263922526815112646932114458012557059694803686501527902687153,
            19959779986770356820096007220078075017343496109652188348073025481070612435743
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            16009396191818987288649575116291667423871382760097130651701341727245465833984,
            18456706987066293762691778737288758279162194737464102695068008273383231802542
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            13915424888986883559082759479141725322969612158207940245784233897001665387734,
            17957242459442107012734062121530472115111940701778385717645143929521973400059
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            19466931008970376587486018315605694709718017902009971641089299715471866058792,
            13570665691475958056926204316679743356652464840993151973007111900347008363900
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            883664025560355018106798526935979775998571234567301370160133652194912426135,
            6919870536475524141551012403404673478698303689534298750059967580794820760653
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            19221076078614171780345394323394512102246003768685596703012013042834542155174,
            15728448850962544004694685708395648473748795663253209017443957533468052911437
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            5562320670244602216061706808076195420823796321587164518694934306695311568859,
            20845846283159376351807160218867266246398695190340747136577812320361855121127
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            15328805730322138577744857677622159098447245851770927165441972629332171507607,
            17352117415621840499388393107765993281717994811415997253667056506948780082937
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            7874994112125801850397109561244852111888096277613624920431404975052716335542,
            14438889271344124280269499369827240539198490215469893481881269826232535857298
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            2750031709756885494023313077052449511355704981591744327072973117218712919694,
            1238754286859051032455297277753612657154243698914172799950149680016150951761
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            2368210341147088121570108987138476246006503535071956951181844424365740117721,
            13640671621608706521201761740840387156734334837436676285958613699384611870811
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            18804325012550724035906933397081009346733649747313552002672095804725062952925,
            3261353067221916028385752479201688596645856696213330212986996567331119341103
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            17149114635260180707813968776640519537596546892797985826410784736736659432314,
            16921635478311127041406563626722236108356357896082397608096538666645074691392
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            15482462406093562322878123490058722626599777338435374072447903664636750300377,
            9695394374871135459205867452548292872925849683324083920425097385584620869279
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            16223859078775942380902047384694516475284642780200154074074506084012766819095,
            14206272377302059639475346675817167539338809763990409097356845695881111076541
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            7402189179122914278579837718555221514933516203853562372720233551398923170749,
            1918042556877600932910807603122370507281574572838178644458703507797452872968
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            19489288699915019414155747130038235721957194795800767929612083874513398013575,
            4082961960582340486895548149942254688319104954559646487371907967108111657003
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            11346654189745757262585370732499506211856099297731630781365142413258505602465,
            19895405287699253724793236842694970644615665934802090951376282384547717565515
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            21641291895780513514340316461140890225856349787801593134342947958137262938265,
            21716240235254722203930921385355607558871751838856060008241021229012112636197
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            11110525354863329423477385053307320164969636290717000786916846038461050828811,
            13347901971100422679232833542112951830690280627673995758321727217297905253153
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            21506626756081948937582411244792258480566156507042217500995546237776744211656,
            6735845252767885565399095788856175382379195899998494932120913401354299317653
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            16823882902704355776584420157555074606766049087976957942600932215470420796992,
            20370413002600176742871984446667696977833641976013626610334465239598237337722
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            18098545775717620021893638931066807227384997839382528596557685505150819786374,
            15619556675493622173019128102705282282398927092717463637588341064640509545525
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            14071285102858909378203192139486431807349694893701299621800539024706084217423,
            4321821776963943613737577129877829189625386757647327708705340372856695828616
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            1688602974621835355388817515987960137347478205449212713019467964583589732844,
            12418710734824649979117925869575761695322093967637918394508888758073034020821
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            13044684553964748565146881862607966282136880802791164126336597109798017776806,
            9350043261198136349862140398135313434785327353517085731205437149638483221196
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            17349027070586972586076731789691385476316081064830931100932987890586439048437,
            601880020489834668785577230790025412532040648997406307368546638860867059190
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            14294183281392054374025793790803523782403041017568961460471972547654996758695,
            12637204555337596184099292034046143298666472700911835941381451226253125826317
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            3623571979458296284390325298466290672476037495017287552268133384010105791345,
            16799817068694311171448339211736910653711177133256387281585896850304799174276
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            7236304689601010775397037507913155595318861859588253493565505495602110995560,
            15794511309298949446219050970133194200548392537791615144603908792767022638322
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            2064742726079083724972250382285846360281933161544983913380814898621905773000,
            7931721437874363335548238143759278434381183719484534213051176348584024994526
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            13409364230851954780216819717529378985967678174148398557447343734606659011236,
            405566595748169304011312686236439609980429476724611799199393271312061460904
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            17963215857713522671181600981053787531429895747265750180360050362682613057673,
            9692539053375084058636905797240054952978278578290363333728274656021156321635
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            11921917457183612958135709302025220899098490231974760816418597340059959566863,
            19368716278161996266900406106207899264226180405236365986664454706867122482592
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            17541254740144713519929559318970561757223714127479708752128800895301033705252,
            2275765780757261190090975617862365308870691815138029873637384464403694795680
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            10245028437258455470514274690164748321322647637412168506532714488155117435791,
            20086431661824235295699721195940326935626891313681601158652912633046555430230
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            3634039621240529614898438771198334383813599790531417451007996582544517694216,
            2766919801978938910079956748859603900334512248604529547935237385896592966102
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            21782789843568051420805328596226010994666242079212666232981635317938994092654,
            5115692817711702520427585940094593678135140629016265817399653656150453593082
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
