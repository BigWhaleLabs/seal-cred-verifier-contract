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
pragma solidity ^0.8.17;

import "@big-whale-labs/versioned-contract/contracts/Versioned.sol";
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
contract EmailOwnershipCheckerVerifier is Versioned {
constructor(string memory _version) Versioned(_version) {}
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
        vk.IC = new Pairing.G1Point[](93);
        
        vk.IC[0] = Pairing.G1Point( 
            18244240149208597112351485133182370740580452660057658972652998515576452753608,
            18803241197222069961375215192243693275293001588554709818862403241774014090584
        );                                      
        
        vk.IC[1] = Pairing.G1Point( 
            15152719341254877747337355090785111677263288922742956732292637734297597741535,
            6529334971836029248917490331612731047664897822720166664392162105814868051253
        );                                      
        
        vk.IC[2] = Pairing.G1Point( 
            4647700873872480180105656797954586067358348647004592287003017828813534483464,
            3051885550267110571610043588312493855215179135421046017425291809800366440773
        );                                      
        
        vk.IC[3] = Pairing.G1Point( 
            14937289272438922857297094014410509475345080200121795178753904810011537015734,
            15964405975735806431444004255008425207929812594996316463299725545513627737787
        );                                      
        
        vk.IC[4] = Pairing.G1Point( 
            4989420234315910093338165582765581019894050669369390435874765132128744805026,
            11129135028928540510788367656509696478019901897283071419748393410602801458335
        );                                      
        
        vk.IC[5] = Pairing.G1Point( 
            16289782029261554427273735082887600002973976000147187168276873080395369146451,
            2219705220094236956056161619341110345036726836180944394922620598961826724781
        );                                      
        
        vk.IC[6] = Pairing.G1Point( 
            10888264714627069025674310774043455638401823342518210611424181175800236582269,
            18538139222002015876034890639750363344074498809023245854128718241179424606872
        );                                      
        
        vk.IC[7] = Pairing.G1Point( 
            19618391271624281111547386606380158354477040900608465493898406380219328410634,
            10664264460060886195378088825468912002026843019214540375030580848220805060480
        );                                      
        
        vk.IC[8] = Pairing.G1Point( 
            1902899028795967355054103858014802171207203045992541908523695775465764827646,
            7821165599911016064211193012521181757425257403121986633430874373543609466136
        );                                      
        
        vk.IC[9] = Pairing.G1Point( 
            13808446574503588584051549076219899315771894890617458124611908720122040768818,
            15010535742747773678544065282397295017402018604173134862263546706039197030478
        );                                      
        
        vk.IC[10] = Pairing.G1Point( 
            4280986955168304396509721805483149746897943209554715789964494097038452917608,
            16111654552619450361778350665197505419074921394343748667299600655122720483843
        );                                      
        
        vk.IC[11] = Pairing.G1Point( 
            6094820663419865710976387324267529534569320108129449471594456108681513535889,
            6445866586941464648507941141274718271661628217924483817711035004286908171955
        );                                      
        
        vk.IC[12] = Pairing.G1Point( 
            20034640014051763332534813676541967495843207301535459683438505218388779027044,
            13435204085176712295131486912492781944608610980223604101703796126612810520234
        );                                      
        
        vk.IC[13] = Pairing.G1Point( 
            16097817190755302654737755116173213002552460515200567106950389365676079698053,
            8795011457457696697587095215462098274741399670868602258140058961703086018411
        );                                      
        
        vk.IC[14] = Pairing.G1Point( 
            3269570771404505526754235176958755808128274593417061914399329157939717005801,
            14644940495966784811968633316120479236734561763364768267881963012388123632128
        );                                      
        
        vk.IC[15] = Pairing.G1Point( 
            10160745958699425107929283363858666782416808716242692777761818383362366479921,
            14802431770537309497502236579866267390886670400759186705078941069343604805012
        );                                      
        
        vk.IC[16] = Pairing.G1Point( 
            18782544262453364756573938593477221069441153747035371485584850545233140920815,
            14661242499917431788151490047210838371217534071843637248650041639183668506908
        );                                      
        
        vk.IC[17] = Pairing.G1Point( 
            2869736047894269567892082487197027587963376425330561835062560781042020825676,
            3147202200279178539237836369264245263293788266584347076955571586697584403319
        );                                      
        
        vk.IC[18] = Pairing.G1Point( 
            1765460528698992884669442181000157793548769795671064994303296073685996063772,
            11467413626495638182149179156717738669241294049569463795861894745549098899893
        );                                      
        
        vk.IC[19] = Pairing.G1Point( 
            14216253709045682454779337618173124266233722233198691676299734761620661838071,
            1033549127618000265592543637576675943554423278274655261336808969170430934542
        );                                      
        
        vk.IC[20] = Pairing.G1Point( 
            10049584795298758975787494150719018468117785665563403952248777990683938574289,
            2872576142632294814151821421528255485754973573224563374101256183913758353832
        );                                      
        
        vk.IC[21] = Pairing.G1Point( 
            9271674261815354494523917661211434260533667189004341958858492703519823037086,
            3847881826717926908623039744273054664841601809889628781025173266623998614534
        );                                      
        
        vk.IC[22] = Pairing.G1Point( 
            3339040441282541387751818793946403977994898772167865583049636683366325111478,
            14942655070781088144108721202088020909275338890756772098399200149245959965698
        );                                      
        
        vk.IC[23] = Pairing.G1Point( 
            10293884739330308004917389049899607916396377461331568339294451207335842021695,
            9751174346981109312913015294459635235149213428861525821262121651720073057311
        );                                      
        
        vk.IC[24] = Pairing.G1Point( 
            20557395982178532971899810651375039114273883326670069489984571284141115714122,
            18121435849551365486292630855082453282740652928917869541103690267401260751441
        );                                      
        
        vk.IC[25] = Pairing.G1Point( 
            20707090411363779832900439758890457180918615992440182529780142474657771667003,
            5902364734833343633608046566182836469059381041145331768362052056959219801782
        );                                      
        
        vk.IC[26] = Pairing.G1Point( 
            3776900709844074860520408570792409079381286052909296843196341486157584329934,
            5857489367470353264965822579873994915413936710840574163411124956385310062284
        );                                      
        
        vk.IC[27] = Pairing.G1Point( 
            14996430799243712434102484707790921997591538681324404199500257600930099597794,
            21277491815356343584512656821613951209304414552431243326850594930178174065686
        );                                      
        
        vk.IC[28] = Pairing.G1Point( 
            16050189061909888196245705843988876904188143263826383031955717676030053857229,
            15459499921578506478198642410439904610875601262206460017088256439342133383557
        );                                      
        
        vk.IC[29] = Pairing.G1Point( 
            17744174685310407871074796907976665329707788081999474442823332324493086682170,
            17438681569364224513818323841717302777792044754154653408849754172671474357148
        );                                      
        
        vk.IC[30] = Pairing.G1Point( 
            18967930684925648716258238847541214550268951076849072339765923838639719367725,
            7101842687207310461399583856637344911177778622150586273716110276640945749210
        );                                      
        
        vk.IC[31] = Pairing.G1Point( 
            19910983123924547279595336986594626670297838015831858384364469438268023786672,
            8043651687671449877707033437116029736580658045438337875265420005583280896265
        );                                      
        
        vk.IC[32] = Pairing.G1Point( 
            4048824595064662037542749376755016413096870257275207711709557437448141771408,
            1172512152627048906245763977302375629311435251427000729747443757400352353787
        );                                      
        
        vk.IC[33] = Pairing.G1Point( 
            8460568357647870076387979953624868544706158901840794410092871417158741122714,
            4244938559180095855296576578305740504176063228989727277419332274186415131471
        );                                      
        
        vk.IC[34] = Pairing.G1Point( 
            13770267070317681057323815692482848871147174318226611234001768649208867390687,
            7082778029523719305867828873410318359248086504039631689168904124206125009228
        );                                      
        
        vk.IC[35] = Pairing.G1Point( 
            8122023844627337249668020489917094722060305039659459343946543595131408884182,
            16168217153114908693881034555580143008465560013925182415833579657524257202614
        );                                      
        
        vk.IC[36] = Pairing.G1Point( 
            10310915351587059625450295801255718232031055505754114537777336776299971309416,
            6181972611439713988506895112375929976948632588132108242186843364687227760834
        );                                      
        
        vk.IC[37] = Pairing.G1Point( 
            17587109871028748921446786186421702697409830343653820339224240692756386331366,
            12824376364195383457545847287699155020112270955954895681998042320223520656828
        );                                      
        
        vk.IC[38] = Pairing.G1Point( 
            1387458502735492102874902816965604020046758898638086594703880850444711253275,
            16089532669073965241378123536327601575323717266925015548649420764296706542978
        );                                      
        
        vk.IC[39] = Pairing.G1Point( 
            13347514919012439649084766152915011743701179373408257758152648638075195554677,
            20953679100400032014451971663847864248030216738225746604289927629410130517579
        );                                      
        
        vk.IC[40] = Pairing.G1Point( 
            20066034579546327603703008904384874507533231666133149724272007493917840587077,
            5300604898309862988928630639721278555390889574043314669221691019529507253482
        );                                      
        
        vk.IC[41] = Pairing.G1Point( 
            2108502124356078253660504271141674581421370229669251048528794001635836322757,
            1645442982429021799514071518241477095072206098772023625408977554543543187407
        );                                      
        
        vk.IC[42] = Pairing.G1Point( 
            5360093194930484451572253814423304185951014580439901699570013219391172901108,
            15803839898846207785900036075727308159510802509795909745453443478498835775829
        );                                      
        
        vk.IC[43] = Pairing.G1Point( 
            13863857761831679370142055229336613072222165940357433678000069937098672887137,
            16574193363234373066713616242328339586400541368371223175049990409657301232788
        );                                      
        
        vk.IC[44] = Pairing.G1Point( 
            17090798447373504569061866816032909170549015053275111598667517838211424475145,
            2868825752678200176861969496635864772231622183463155640087564953447575239323
        );                                      
        
        vk.IC[45] = Pairing.G1Point( 
            9718833213793598068109048615467007676688291932831143718523525265528220161702,
            5351441072784126851601799778988106282086651475052924639062794038844583560123
        );                                      
        
        vk.IC[46] = Pairing.G1Point( 
            16465914082102585933597335707933119276800054131127537303683883836163579086320,
            3380406798601967723544000000359252924392612620321759067706593246528016767549
        );                                      
        
        vk.IC[47] = Pairing.G1Point( 
            18417469668920331185072156755945589070057783358712096366486958312121847039655,
            17154746169675651755453967102985469347257374154297187284900945326963891761650
        );                                      
        
        vk.IC[48] = Pairing.G1Point( 
            5325594083335431309295957350005999921643649908863952071428958445474923534086,
            20089291255201675809422076338460853687118356527576694032152374332323791022646
        );                                      
        
        vk.IC[49] = Pairing.G1Point( 
            16525063738038518742641213393849582815066596005737092046070380957472699195413,
            4384974511159499633154733872919795987509358175115123589663478292197294133103
        );                                      
        
        vk.IC[50] = Pairing.G1Point( 
            1433498350137206553225141512188205032353442599561509140647033475350386737786,
            10110533470569995742808066649099797002951267970677027330214492829099415822484
        );                                      
        
        vk.IC[51] = Pairing.G1Point( 
            15083645843140437848251612777424998734119255960694381799676050726781578534652,
            14228160099816014670353667495740623396596142293334562526244445545116787024539
        );                                      
        
        vk.IC[52] = Pairing.G1Point( 
            1703413124791588361192845510464271688257941530107644631310047342228186510326,
            6340855927805688759306398157705145606225261329025175020171193656066758088572
        );                                      
        
        vk.IC[53] = Pairing.G1Point( 
            10405734070143613250151198555700195155440973564984931216708095273896428311539,
            2798474696936832403089149207312590191419129558855102910150403517436309894864
        );                                      
        
        vk.IC[54] = Pairing.G1Point( 
            21846433061125821016294987038841488925796970403791291285801569110061543806062,
            15206826718960750371342018986210679586516797932908332277344879048098951071673
        );                                      
        
        vk.IC[55] = Pairing.G1Point( 
            12052132842052397774011072523647959261363811939515693328155443559111281006164,
            20519507240049590586252637229075339286728742144809502795687211902517546991966
        );                                      
        
        vk.IC[56] = Pairing.G1Point( 
            16872689681346681425825712973072191147376525143314781330849267185774440584895,
            16404472299271116783114043885072393717944437703894475660777772174260619093617
        );                                      
        
        vk.IC[57] = Pairing.G1Point( 
            7393336301643093771608931745591197504689948225499260848410232497985926592494,
            21349648976665149006048472969883649233524441318945351110161344023914655456464
        );                                      
        
        vk.IC[58] = Pairing.G1Point( 
            20540521299150719985162930079699236398472279964755005414950601260888719215529,
            20286467160095404769850847071221913708838255385134089932290557581523414413674
        );                                      
        
        vk.IC[59] = Pairing.G1Point( 
            9376290530915371659419542699874380447517917825824795868619921600304713012303,
            18972394525544411429951195783650208117572582394600458178659048909876333016033
        );                                      
        
        vk.IC[60] = Pairing.G1Point( 
            2298019610201859457108658322047595822169059700785862979838031684901463894836,
            17219518613980267242734556291547857243793111590346382122798580102150388801505
        );                                      
        
        vk.IC[61] = Pairing.G1Point( 
            20740560029016124060648439268937804779928102608948964632000236822519033559308,
            5166489990643832736412388557152342820506183945413957708709251032267814612410
        );                                      
        
        vk.IC[62] = Pairing.G1Point( 
            14860372499857906222289443529590922565131385674930912446097676188207862917139,
            17468926633532071057192553135024539193624850884240282700733280046456941433798
        );                                      
        
        vk.IC[63] = Pairing.G1Point( 
            9334304971264525129047964554904848403423217304446432167526944304887041381905,
            1381279876856751282403381762928988715639518617350429539108769849323369169843
        );                                      
        
        vk.IC[64] = Pairing.G1Point( 
            19322353301187148701698316587251297196118812963839392671810717582878895221061,
            16950207335383066276008156929827435289669621347898910977185255715470488880956
        );                                      
        
        vk.IC[65] = Pairing.G1Point( 
            16023307354306807430074196985799663193784651913498237264325480981534741354193,
            21659477862860712568842513849781719912520223307619086926411030335066214066677
        );                                      
        
        vk.IC[66] = Pairing.G1Point( 
            20807967449495245610331527758227144094918268825392944623296584083999085370251,
            4603499033672721782597562447101358687726231242451448124398825385326666796625
        );                                      
        
        vk.IC[67] = Pairing.G1Point( 
            4950946325721042968129179581197091599087893079872211866177992944556138845002,
            15742649871215031582998082852252166146663358039527574177934284620853615861319
        );                                      
        
        vk.IC[68] = Pairing.G1Point( 
            6598272727983405328460109039917614792471457549290586713145776779376604849332,
            2474275573272284623299807946868265841465812301428982624001597561671844000975
        );                                      
        
        vk.IC[69] = Pairing.G1Point( 
            17723148441422320996745259407423860259187220316059062379640078488527783793838,
            14574157668038781804389388180643932483560017172299999700103315085256752619547
        );                                      
        
        vk.IC[70] = Pairing.G1Point( 
            12026005876507725313842100047381756466284486500310845701414213256680503981734,
            21730550308524163251603115486177324163230300275600021650630364002423162503016
        );                                      
        
        vk.IC[71] = Pairing.G1Point( 
            20061025957150021363130717154362778396924336859084230079826927555919350212585,
            15884789787442565728735208364159990936069035601232728258358631510217187698512
        );                                      
        
        vk.IC[72] = Pairing.G1Point( 
            6841134468250303974457542820772329598051225049461616228798017501130855957202,
            12136620933166284701069733036848966193598218801652525005258178145565059667557
        );                                      
        
        vk.IC[73] = Pairing.G1Point( 
            5218896638339212221878352576665837020656308846248855774140372777069146651690,
            2563531741494634001588172671518744580014438684438500854888018320741401522272
        );                                      
        
        vk.IC[74] = Pairing.G1Point( 
            7193159980518152272377972200239948255813442142410787222491608278769444381455,
            19909203535261376363446907076916396970632705890447227323231936983434575993793
        );                                      
        
        vk.IC[75] = Pairing.G1Point( 
            21345500477571953397103327054046237516712776877662591665278007779080938077941,
            5627999518938375995867993230272659720860137600283522049168436945485573135950
        );                                      
        
        vk.IC[76] = Pairing.G1Point( 
            11950125081106042572243538515766701861233993738489587659514122853680133563455,
            20295091675777215155035925120081033070559017635952011215778669414868171980402
        );                                      
        
        vk.IC[77] = Pairing.G1Point( 
            7966770081539874790042152422530964822589275316325015035270312452654395050306,
            4807697076906511668745903551452560857615814160199718750859221792537084028253
        );                                      
        
        vk.IC[78] = Pairing.G1Point( 
            14765194821668155430810271269387282323590190780013863460380292070438152250668,
            20651909844134455028003575430419246255336363444591779491207040082374338567810
        );                                      
        
        vk.IC[79] = Pairing.G1Point( 
            586065445908583172016370080889497663857299466512940048242692458056400605831,
            18830181472252046445287597557794313872223434912565220275394766398622045518832
        );                                      
        
        vk.IC[80] = Pairing.G1Point( 
            3005227969949091351948595162904591555657180772990377841488307855817660010749,
            9400884405984726934476938193103913101654053229011628908413336311380563374292
        );                                      
        
        vk.IC[81] = Pairing.G1Point( 
            110531032328883154564770052793962619177576621686428234877457705114754797065,
            2200929260892406765296932072326226670128733969643460457374925057918315053980
        );                                      
        
        vk.IC[82] = Pairing.G1Point( 
            6928504679472042561741059900535498286138987068324640682121063247593869081333,
            5568323024726989274994721218300559674159821083472934458069052606869978232139
        );                                      
        
        vk.IC[83] = Pairing.G1Point( 
            12012508946926270455681015777749806136204983802262140511531695669971250612838,
            21156671934193003619945261602684875504241765551937784963209788052979536085537
        );                                      
        
        vk.IC[84] = Pairing.G1Point( 
            4514947965134777676100821520004660031935599194281238865245066106936225162109,
            427490854594646297293535383151494225400240717566700012613463558312159132770
        );                                      
        
        vk.IC[85] = Pairing.G1Point( 
            19077332522956862939110781853312061550004795763168080548416281134518710497633,
            15086934530974117500686182086338246322924231907659923089593177742035775852469
        );                                      
        
        vk.IC[86] = Pairing.G1Point( 
            18730744692683469023511690913607506205257428991161014035461462522564330532315,
            21000623588198512104395966279778908774535549026615418901669982165682216400091
        );                                      
        
        vk.IC[87] = Pairing.G1Point( 
            14767402114138256452849814928327822997406868231968257450315305320901459206440,
            7418494093759023199347181943634238393334632296160462365950601449183440173718
        );                                      
        
        vk.IC[88] = Pairing.G1Point( 
            13071151410490975225975422223531661644506641321501510909384094362163802326349,
            16612697367617095050820310634455714818653094438312267542476547002882796357543
        );                                      
        
        vk.IC[89] = Pairing.G1Point( 
            10676371859063531792894889479540082467110465847916290339814989546793253967893,
            16280044737838191914593981291594531184644697190536153475595481882952472883603
        );                                      
        
        vk.IC[90] = Pairing.G1Point( 
            10733482087513016765052847755302000965146887654810247520532244992302627214669,
            510883823530775908676424306429314970483552148301552037657103833280157364158
        );                                      
        
        vk.IC[91] = Pairing.G1Point( 
            13365309733995495884789118289720283544658126404223533713566147866451671120189,
            14536790619930881970579319643897836234922496519693174227401160485932383733237
        );                                      
        
        vk.IC[92] = Pairing.G1Point( 
            6825818197808949396556807363226566531597411112679191443707874346704099136128,
            10709519376845980869984637428790985715339973233845015421262144872298944799692
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
            uint[92] memory input
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
