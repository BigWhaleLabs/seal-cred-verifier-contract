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
            20819804608758582607499444843234293432888086969881624403546527777358162051233,
            20408334049286615924668436757938723038791483140020352483169197753059239096618
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            10022161438613893875751580534449370618226894254598565115544742836700151744465,
            2301169924921332092010525182036237748251382393132380551853043115604411823475
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            17461208425154132601876411405629981537552303024844010484528086915270816354495,
            21418361803785175141576179209859306617085957933435961094246512414834998917679
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            8333428516477571866206331378253827891346742405910230396622431991255016417415,
            13313960015108120847391671163804876233119025745880642939121696423097241673756
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            12077675959054217118572692586413016448505465166265803001822862409692881990880,
            8021064145872772177962967466060780161111998664311255088763198044836317001481
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            14894258677942184641635449324940642633491398776068742471720480459587744366950,
            13292078256936576303982841732049604763703968117974546114074177238296845887611
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            2016168720371910682991162612287903862847203038355627058633119333439630088487,
            308695350840081694906649662190109874901307330461736882929424548731049260917
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            3458917356370722729307429783392666133909575990840683721324471960254089725599,
            11372401982326799290367624006728674180972236343685013867958709413778141621979
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            12937195996988402331462814896264932126435485247295556180461877070607147203753,
            12285208568215410266737906862569899582682841562861816185515589898682590476153
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            13921451246796424340501978618558356520642220472087349417759277123210734363748,
            19398210841538973706907027219989354640033746582759624357586475704221050040121
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            3427600076402427012459244472719219941539465884230209448796230417732286050489,
            5704958527257041445561597349088540610791988008330095679382527193206451264829
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            1510227887312700973236390976364012093733662837481794269365506392093865162575,
            1380404454225732405951892314761659419884346329551328158522449561004040233698
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            5974481680116914340692634834204847345323887370772511517641285688270781267325,
            12989170192591499560349018542509787023776155807602865906428574132518843831274
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            8150086638493799984348259079398686930561982369394348958696043241534816063224,
            21397839695220068617464514664775515366192643001244499961648678418133536397303
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            21409774936761616516730924427343896397883616247603672567645095818164900152015,
            10062721608732190672357728058314108314200298281319388952313624916274813088701
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            17250161659673597211545728629378097533144632971203952055037022457009286550378,
            9323648836120228617785852781185786922210121164491477333354356343166797237808
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            14012817012568245404583568992583551241450930849673021544462337454847016338757,
            676662533244439907018487027477221446201327858716694454707526658229681916491
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            197289144633617523051506275272219433409638975801871964546259843581984188673,
            10686604564724714108125204884470108088649745796308792060532707881257319134575
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            21557035593314810164554664864531219368614253806024510388849472390658498758157,
            4586801895756403634534243547817853517755243726336343226208614886196570122652
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            20269882689825777709463241844598295038518896233613527737051908573899249317498,
            19811808312340789261537304278115487521711272748211322818977788032852747527069
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            4717628005524214165061013687267530447028607323115497634470570664314398065531,
            20672609436788390768266728536947471165060263696870686985254767519627918730771
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            12208467503359581900637683669269375290733092764889309081616720158622788445742,
            470619054686038310843708165160615266861522026331363000609394230722303366997
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            11497790851073543023407334098691862492504318840837748852644126623333473058819,
            3395103377883688098991596950015503095042310821010625774753096445409884636360
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            8632584577762614166118658877059511451994060491221211197534094744464948551974,
            538241190562185611801828615488667606227126578197199213633208409339549445895
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            2836428905978633366812438070016726626109837563142513194877639434005008667600,
            20790441706473106777629180815321086801591417719149072194603571709673799680226
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            13285802978919344437528670243963808509543254362428108469343177600010076038848,
            6696166956428536617136341576906166206643006197505148451289848198343610859536
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            16619068492684884759109748563528116545644587322481189388258471038882578813055,
            12721734423100794205429496119960163149761512867623681540523770203465576451932
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            13082458487085329601415185528594989846781464886708908824590389650340529044817,
            10510950723777616595258358876176149234669196167799163422320208514928834439946
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            413811343939972825360531180245823785988358708043116741732726448416925711267,
            18674939879128411128658767453812222677580997399868172298751033945916009942459
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            15637823910454357241680068565043263075869382282266021993572197895326670415872,
            2922607208469313863196289149366335726901101579569972840766015762852250858852
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            8037527311839381169575192427861847292830637388780373176141779781280683042755,
            3936117939096408226282831077691669851956703616703072985620652931407277663975
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            14713252368980129756371022754327129882089122360408726508469284815508099478771,
            10116820242518562070891935949839149737371093572621592795207569060996014022855
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            2606811178102479352557015888430916482723492883587500011232850861684602772790,
            14209815875577382697309716103744229222220760817402238853403819970202992935282
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            6553716894668184261839171458246187969454190606548464455315882929580274268996,
            16669946393370200275952518263717511913769811234672052594982920639188176218564
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            12849154851130451458357694684789245406370450225685531034939933870506995919473,
            16684748280806251396488848506519604284779628992794804934735458266768413501511
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            14845539351795954558867434573262482441764799647122589304142002678908399106521,
            10091715573138455341679991383238454175817206115247952033819131730941789643707
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            7260958738186255348361233901558972895860786218961081579646997787236438895322,
            18858881268285430978491715904002769591415413576642940499156519368414172535876
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            8267646617259488807094244070417495360248967480232501501178025495526870388128,
            17066725436856587338714877795142274530713623154098852307300767717292638926526
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            15708473861605153705605435573083444717284481835419689815361051097411697692197,
            16875463647278107574114983409030478193684912742654847153907979529525439570660
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            2687090763635124448779838337267004119983372892208475927467778149829399011205,
            951953612793346441062230947401303136759855347054781099668451051898392605195
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            13222128683186620248510209641832335081612881320223367626993998533519610891804,
            2109690134349289212604471115832243352319988338994822885658931937213061289237
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            5883612331320485765427477724527597745075228523289157941961648275393608969297,
            11535392367884679159461560584466790941095530303295322813686401241649907232250
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            11170023900596153584979106354364859103819867948635376159240064472749430192986,
            14387703234463090037136764903569809285055836216505722011689796480830558766342
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            5050690760810313017606115357900260644311719940152635603209747985701661499817,
            13852673643887301812479399520942364721937778515972773589965531961829045776409
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            18105729346725214214839436682776842687972627804007530450799831006719392029539,
            19563313433481215743919945426190478119709615913014871459094056610278438491753
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            4866467511974654395503778827167736177660482726525082447644840555508731558656,
            8810571411627960524748976505820062636257241637687388079722038492020569602325
        );                                      
        
        vk.IC[46] = Pairing.G1Point( 
            17251502455150218321193492074777310061334106907086679670042041940728964281848,
            359867910356019517426137927792962182717444290689438607480311563494526298467
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
