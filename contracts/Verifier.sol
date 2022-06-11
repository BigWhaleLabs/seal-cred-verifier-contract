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
        vk.IC = new Pairing.G1Point[](45);
        
        vk.IC[0] = Pairing.G1Point( 
            52268181566763940211505525772531448339002328515550596770283879666127240444,
            4250076694578270600467472669564353053749498823164766779206453422235820264426
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            8062675385249135616578427539772228474525411623714601986391271428514774213243,
            14783311848953138531552819165268337443070978503681736088680457589249959115073
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            17746643027527547433899590479525165847617010232384391837681117813214155699800,
            8247900527615403370483034947908775874556869946758339368564988094107812393080
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            19905038864591360386041130418225942241728477358595468608648946061024251601707,
            1907117785776009989390180192258660015705691910442302985062612649683200289793
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            17368674641342518234573142774210297968438410174815523338732666476180699754682,
            17148661085896042696011179547064792678401617538646904439152897592487662311871
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            13623739522751992459674440801500121047882297241925704420808488923077286180364,
            17386041478919317643923907514347123456027395181043678102504789466486623383516
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            9461226852230829866313503618645696714414944793851168459607503158174140115745,
            17005761298564370973013395455231191427004811472816320339524177679795046800499
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            672165022246068874518718688671512911866240648829458815822082139599604660149,
            14465650606768904127423146658009154815236727199309551499026557430660806711706
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            4815333691919127349630260554718639636590609976190702822296715708725387081391,
            10168876254650453753919156301669505705055710014281336811886491764253591942305
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            10138058035788545498151756250515045170008581485579798403647749028892015840847,
            19081355789881011302775634652144121315308768300785025499706645296325685719263
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            19914414224289360801333616800848758783512775683175957323944454736895771829041,
            1381451392666789665614663470257400970373743466340785452923555131112886340753
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            8702487760963906282603555968315927075980847542276121530185117603699132033133,
            13694320226873237449439405005260536731210971521194878397769506313717218875079
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            5096174001633590979796535733981144600373053439995319265053888353384974645225,
            2421819361634512770495787272003458110751263577845367818600511366193267038693
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            15947906395857391595001976069274655873467667417116721391392989854954457403852,
            379591413039562739146904216387986921807046447486588722119589524401978414055
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            13883193347522398090875042175705582264222511343706198039262654629908651359313,
            8974721229101454482074144057208734416234857268937420536908852788596215347042
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            11369336288005509489629003686084849923602951117584917099257387048196326835384,
            6367361212618325231886552420347066884404613232781175054634786391513333403672
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            19634613494766125289389826143394919250693098829424412514676244832479259726260,
            8620616752235286891301230299917481890715433476498884063574980711261710897013
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            6916573425666911719197439247072024706466902348835611730458731840553077653079,
            13336107342775679511731757828247833588967469870625624431401964197304499498512
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            21600318229086866408253896001347450289293631350556114148645785477044005684301,
            15621369078511652636954329134585317494506559810065597539114974088444016790212
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            12245537386287481807596216486398559253109796425775017948684069747017058724809,
            4484678282202527630604149855693523079881535066684484766020715207348402613001
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            9868043405073741516140584997854936301492463968034735979185767346355764734177,
            10932712973136718434187773356955883655352026989192642323728005142809607812514
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            8165357051662209376772610291042364365450732621363603762468506256842051009970,
            19823546990070424108318541097258092880108843818527448077706050951367761247904
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            9478859261921147724566977988806528621133260040073605579145170490657808664382,
            21808097352363718477199799603222716455173951672536466802413525214510704079973
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            3560985392124923987939217764395014197078507333955040310909921602056273792230,
            6169502542735407583000354712732930777862270782903900563177063795758287150417
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            19941997870950892497501095935835714913084994579967201893211887894689131089642,
            10188219536132847360571797749468429385383579720107311489146053473490159813042
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            10460257903471473817962046354408151268545609871572696282392516547618785252980,
            5568790280084166959791149105525246742671183442249233030955102698185042094604
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            16868758595302342516918733448663032451687186079609571240178407424433269335017,
            4312502792892102806049314014916570974128249182356053191737196385927378239847
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            1654379081150703574943717726163237650968346077935996724704616012362614345592,
            21586795483657358807717100298806997384285512574588616838256077707739027308744
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            13732055647270591600490978102454123239587264340577476934176713594541411263915,
            18815056851521054439742899787876853089330077757844921248542238313528694801935
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            19198479669502018714307991075876127572825922661940265886129972124419073718217,
            2753927382913929906501226021804946161429931571439892301915467251256599420584
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            12481814883086962940758866560229925009452342351188478735696823684287756821551,
            14326096350848012095739152321084465621850483419998745775978114290369139662322
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            12824305063982093028712627672621853797469337412047333274344424003412640394282,
            1577400798570366382626764671243547030073132986455378204959825094933163506385
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            10360659666292535873812922297297598268941584728949214265703165356634174759545,
            10689834959100487091577295390555290603807674583767211722547172245777334684131
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            11720421519447956772803394409857353244904879269046382549429897087024537801006,
            694416053424030517923810148022824322322298814264388370840513869354106171530
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            13884590290750548633807659687079904388433157588744611473138573032872633109185,
            9483747123949007780755897227017477136835675963526869636936185939049867293996
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            13657769550434222650358082219132774925339476908265203735057474214509895419679,
            19371618027348737527394854061906392234896315714494219113865877949097450597609
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            8553793158301321060358755774844023276605345652963339860175485848270104978071,
            9770816481780354518763072209460008403192998628168322957220225837135539950392
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            12283826334131538027470355945485777103805844103355831849050495174340256418623,
            1036328563666706290519139868760256739833955505753277865091271540962786856734
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            16385430393143180880555100340419955277763551315674320273111576773589236176094,
            21248574468805570972703683209090211438771884640719151866932762650024809200025
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            1955621374847292904665319853388986939498310872035913377345831748639649060474,
            1271316071299065474751588934845536562555495553282628763760372513418702966258
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            21037098440594010436336230475081907897743415724077765748332893181414283148002,
            494257087869209899726829815976760747589340628744786903942753266204367609324
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            15155420736839509242900493002108538305913425926369821002356421829276489165921,
            12604153131107537197170629937860265707758937965667048497356000372091472237841
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            2117747408026258945182837076981340660122737068885038282415615695559416443975,
            3984138576622720083535444387714200791767256737883364042115537407906381047837
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            5816764920479017500372504135641812141592015602449390220747924067245093514819,
            1264829978167611038015984055676478418644616724616252162193573025433046415081
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            3738939380050551403009954088423952552965663847263824425151099210969882869818,
            10503014396673398362025014654596541012746890297227261482865195497529831130295
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
